# frozen_string_literal: true

require "optparse"

require_relative "formatter"
require_relative "colorize"
require_relative "application/options"
require_relative "application/actions"
require_relative "application/appinfo"
require_relative "application/irb_context"

module IParty
  module CLI
    class Application
      class Error < ArgumentError; end
      class ActionNotFound < Application::Error; end
      class UnknownFormatter < Application::Error; end

      include Application::Options
      include Application::Actions
      include Application::Appinfo
      include Colorize

      class DefaultOut
        def push *args
          puts(args.flatten.reject{ _1 == Formatter::VOID_OUTPUT })
        end
        alias_method :<<, :push
      end

      attr_reader :opts, :config_path, :config_file, :out, :env, :argv, :argf

      def initialize(env:, argv:, argf:, **opts)
        @env = env
        @argv = argv
        @argf = argf

        @config_path = Pathname.new(env.fetch("IPARTY_CFGDIR", "~/.iparty")).expand_path
        @config_file = @config_path.join("config.rb")
        @opts = default_options.merge(opts)
        @optparse = init_optparse
        @options_parsed = false
        @rc_disabled = @argv.delete("--no-rc")
        @out = DefaultOut.new

        loadrc
        yield(self) if block_given?
      end

      def ensure_mmdb_files! fetch_when = @opts[:mmdb_fetch_when]
        IParty::MaxMind.fetch_db_files!(fetch_when, verbose: true)
      end

      def stdin_select?
        !$stdin.wait_readable(0).nil?
      end

      def read_from_stdin?
        @opts[:stdin] || (@argv.empty? && stdin_select?)
      end

      def each_line_in_argf_as_addresses prompt: $stdin.tty?, ps1: "> "
        index = 0
        print ps1 if prompt

        @argf.each_line do |line|
          raise(Interrupt) if prompt && line.chomp.match?(/^(q|quit|exit)$/)

          line.split(/\s+/).each do |chunk|
            addresses = IParty.expand_hostnames(chunk)
            yield(addresses, index)
            index += addresses.length
          end

          if prompt
            print ps1
            index = 0
          end
        end
      end

      def each_address use_argf: read_from_stdin?, &block
        if use_argf
          each_line_in_argf_as_addresses do |addresses|
            addresses.each(&block)
          end
        else
          IParty.expand_hostnames(@argv).each(&block)
        end
      end

      def build_formatter fmt = @opts[:formatter], **kw
        if fmt.is_a?(CLI::Formatter)
          fmt
        elsif fmt.is_a?(Class)
          fmt.new(self, **kw)
        elsif fmt_class = CLI::Formatter.find_by_id(fmt)
          fmt_class.new(self, argument: fmt, **kw)
        else
          raise UnknownFormatter, "unknown formatter: #{fmt}"
        end
      end

      def formatter
        @_formatter ||= build_formatter(@opts[:formatter], colorize: @opts[:colorize])
      end

      def ip_to_data ip, colorize: false
        ipp = IParty(ip)

        data = {
          type: ipp.type,
          prefix: ipp.prefix,
          address: ipp.to_s,
          cidr: ipp.to_cidr,
        }

        # -r --resolve
        data[:hostname] = Resolv.getnames(ip).join(" ") if @opts[:resolv]

        # merge geo data
        data.merge!(ipp.as_json)

        # -l --language
        replace_names_with_singular_for!(@opts[:lang].to_s, data) if @opts[:lang] && @opts[:lang].to_s != "all"

        # -a --all
        data = summarize(data, colorize: colorize) if @opts[:summarize]

        # -e --except
        # -o --only
        onlyexcept_data!(data)

        data
      rescue StandardError => ex
        @opts[:debug] ? raise(ex) : { error_class: ex.class, error: ex.message }
      end

      def replace_names_with_singular_for!(lang, data)
        case data
        when Hash
          if (names = data.dig(:names)) && (name = names.dig(lang.to_sym) || names.dig(:en))
            data[:name] = name
            data.delete(:names)
          end

          data.each_value { replace_names_with_singular_for!(lang, _1) }
        when Array
          data.each{ replace_names_with_singular_for!(lang, _1) }
        end
      end

      def summarize data, colorize: @opts[:colorize]
        with_color(colorize) do
          latlong = [data.dig(:location, :latitude), data.dig(:location, :longitude)].compact

          {
            type: "#{data[:type]}[/#{data[:prefix]}]",
            hostname: (data[:hostname] if data[:hostname] && !data[:hostname].empty?),
            cidr: (data[:cidr] unless data[:cidr] == data[:address]),
            network: summarize_network_detail(data),
            name: data.dig(:annotations, :name),
            tags: (data.dig(:annotations, :tags).join(" ") if data.dig(:annotations, :tags)&.any?),
            location: summarize_location_detail(data),
            time_zone: data.dig(:location, :time_zone),
            latlong: (c((@opts[:fmt_latlong] || "%f, %f") % latlong, :magenta) unless latlong.empty?),
          }.compact
        end
      end

      def summarize_asn_detail data
        return unless asn_number = data.dig(:autonomous_system_number)

        asn_org = data.dig(:autonomous_system_organization)
        asn_detail = c("AS#{asn_number} #{c(asn_org, :cyan)}")
        asn_detail unless decolorize(asn_detail).empty?
      end

      def summarize_network_detail data
        network_detail = [c(data[:network], :blue), summarize_asn_detail(data)].compact.join(c(" -- ", :black))
        network_detail unless decolorize(network_detail).empty?
      end

      def summarize_location_detail data
        continent_name = data.dig(:continent, :name) || data.dig(:continent, :names, :en)
        country_name = data.dig(:country, :name) || data.dig(:country, :names, :en)
        country_name ||= data.dig(:registered_country, :name) || data.dig(:registered_country, :names, :en)
        city_name = data.dig(:city, :name) || data.dig(:city, :names, :en)

        location_detail = [
          (c(continent_name, :green) if continent_name),
          (c(country_name, :yellow) if country_name),
          ([c(data.dig(:postal, :code), :cyan), c(city_name, :blue)].compact.join(" ") if city_name),
        ].compact.join(c(" / ", :black))

        location_detail unless decolorize(location_detail).empty?
      end

      def onlyexcept_data! data
        if @opts[:only] && matchers = create_matchers(@opts[:only])
          deep_onlyexcept_data(data, matchers, keep: true)
        end

        if @opts[:except] && matchers = create_matchers(@opts[:except])
          deep_onlyexcept_data(data, matchers, keep: false)
        end

        data
      end

      def create_matchers expressions
        return if expressions.empty?

        expressions.map do |exp|
          /\A#{exp.gsub(/\*\*|\*/, { "**" => ".*", "*" => "[^.]*" })}\z/i
        end
      end

      def deep_onlyexcept_data data, matchers, keep: true, keystack: []
        case data
        when Hash
          data.delete_if {|k, v| _deep_onlyexcept_kv_match?(k, v, matchers, keep: keep, keystack: keystack) }
        when Array
          data.delete_if.with_index {|v, i| _deep_onlyexcept_kv_match?(i, v, matchers, keep: keep, keystack: keystack) }
        end
      end

      def _deep_onlyexcept_kv_match? key, value, matchers, keep: true, keystack: []
        fullkey = (keystack + [key]).join(".")

        unless matched = matchers.any?{ fullkey.match?(_1) }
          deep_onlyexcept_data(value, matchers, keep: keep, keystack: keystack + [key])
        end

        if keep
          value.respond_to?(:each) ? !matched && value.empty? : !matched
        else
          matched || (value.respond_to?(:each) && value.empty?)
        end
      end

      def dispatch action: nil
        parse_options!
        action ||= @opts[:action]
        action_method = :"dispatch_#{action}"
        raise ActionNotFound, "unknown action: #{action} (does not respond to ##{action_method})" unless respond_to?(action_method)

        puts "[iparty-debug] dispatching #{action_method}" if @opts[:debug]
        send(action_method)
      rescue CLI::Application::Error => ex
        appinfo_formatters(pad: 0) if ex.is_a?(CLI::Application::UnknownFormatter)
        @opts[:debug] ? raise(ex) : abort(c(ex.message, :red))
      rescue Interrupt, SystemExit => ex
        raise(ex) if @opts[:debug]
      end
    end
  end
end
