# frozen_string_literal: true

require "rake"
require "rake/tasklib"

module IParty
  class RakeTask < ::Rake::TaskLib
    attr_accessor :name, :verbose

    def initialize(name = :iparty)
      super()

      @name = name
      @verbose = true

      yield self if block_given?
      define_update
      define_fetch
      define_status
      define_config
    end

    def parse_duration input, default = :missing
      return default unless input.is_a?(String)

      if input.match?(/\A\d+\z/)
        input.to_i
      elsif asm = input.match(/\A(\d+)\.(second|minute|hour|day|week|month|year)s?\z/)
        ActiveSupport::Duration.send(:"#{asm[2]}s", asm[1].to_i)
      else
        default
      end
    end

    # iparty:update
    def define_update
      namespace(name) do
        desc "Updates geoip mmdb-files"
        task :update do
          Rake.application.lookup("environment")&.invoke

          IParty::MaxMind.fetch_db_files!(verbose: @verbose)
        end
      end
    end

    # iparty:fetch
    # iparty:fetch[86400]
    # iparty:fetch[14.days]
    def define_fetch
      namespace(name) do
        desc "Fetches missing or expired geoip mmdb-files (optional numeric max_age)"
        task :fetch, [:max_age] do |task, args|
          Rake.application.lookup("environment")&.invoke

          IParty::MaxMind.fetch_db_files!(parse_duration(args[:max_age]), verbose: @verbose)
        end
      end
    end

    # iparty:status
    def define_status
      namespace(name) do
        desc "Show status of geoip mmdb-files (optional numeric max_age)"
        task :status, [:max_age] do |task, args|
          Rake.application.lookup("environment")&.invoke

          max_age = parse_duration(args[:max_age])

          success = IParty.config.editions.map do |edition|
            file = IParty.config.directory.join("#{edition}.mmdb")
            reason = IParty::MaxMind.fetch_db_file_reason(file, max_age)

            stat_string = if file.exist?
              ctime   = file.ctime
              age     = Time.now - ctime
              days    = (age / 86_400).floor
              hours   = ((age / 3_600) % 24).floor
              minutes = ((age / 60) % 60).floor
              age_string = [
                ("#{days}d" if days > 0),
                ("%02d:%02d" % [hours, minutes] if hours > 0 || minutes > 0),
              ].compact.join(" ")
              age_string = "#{age.floor}s" if age_string.empty?
              "[age: #{age_string}, ctime: #{ctime}]"
            end

            puts [reason&.upcase || "OK", stat_string, file].compact.join(" ")
            !reason
          end.all?

          exit(1) unless success
        end
      end
    end

    # iparty:config
    # iparty:config[inspect]
    # iparty:config[json]
    def define_config
      namespace(name) do
        desc "Shows effective IParty config (including license_key, optional format json/inspect)"
        task :config, [:format] do |task, args|
          Rake.application.lookup("environment")&.invoke

          case args[:format]
          when "json"
            require "json"
            puts JSON.pretty_generate(IParty.config.to_h)
          when "inspect"
            puts IParty.config.inspect
          else
            IParty.config.each_pair do |key, value|
              if key == :annotations && value
                puts "#{key.to_s.rjust(16)}:"
                value.each do |ipp, adata|
                  puts "#{"".rjust(16)}  #{ipp.to_cidr}: #{adata.inspect}"
                end
              else
                puts "#{key.to_s.rjust(16)}: #{value.inspect}"
              end
            end
          end
        end
      end
    end
  end
end
