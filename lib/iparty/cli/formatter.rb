# frozen_string_literal: true

require_relative "colorize"

module IParty
  module CLI
    class Formatter
      VOID_OUTPUT = false

      include Colorize

      class << self
        attr_writer :id

        def id
          @id || name.split("::").last
        end

        def descendants of: self
          of.subclasses.flat_map{ [_1] + descendants(of: _1) }
        end

        def find_by_id input, of: self
          descendants.detect do |fmt|
            fmt.id === input # rubocop:disable Style/CaseEquality -- deliberate to support regex/proc also
          end
        end
      end

      def initialize(app, **opts)
        @app = app
        @opts = { colorize: true }.merge(opts)

        setup if respond_to?(:setup)
      end

      def colorize?
        @opts[:colorize]
      end

      def format_all ips, base_index: 0, **kw, &to_data
        ips.map.with_index {|ip, index| format(ip, index: base_index + index, **kw, &to_data) }
      end

      def format ip, index: 0, **kw, &to_data
        to_data.call(ip)
      end

      class NoOutput < Formatter
        self.id = "off"

        def format ip, **kw, &to_data
          super # run to_data logic
          VOID_OUTPUT
        end
      end

      class ConsolePretty < Formatter
        self.id = "pretty"

        def setup
          @opts[:align] = @app.opts[:summarize]
        end

        def format_all ips, base_index: 0, **kw, &to_data
          ips.map.with_index do |ip, index|
            [].tap do |r|
              r << nil unless (base_index + index).zero?
              next unless out = format(ip, index: base_index + index, **kw, &to_data)

              indent_header = decolorize(out[0...(out.index(":") || 0)]).length - 1 if @opts[:align]
              r << c("#{"".rjust(indent_header || 0, "=")}=> #{ip}", :red)

              r << out
            end
          end
        end

        def format ip, index: 0, **kw, &to_data
          out = to_indented_strings(to_data.call(ip), **kw).join("\n")
          out = VOID_OUTPUT if out.empty?
          out
        end

        def to_indented_strings value, key: nil, indent: -1, maxkeylength: 0, buf: []
          indent_spaces = "".rjust(2 * indent, " ")

          if value.is_a?(Hash)
            buf << "#{indent_spaces}#{c(key.is_a?(Numeric) ? "[#{key}]" : "#{key}:")}" if key
            maxkeylength = value.keys.map{ _1.to_s.length }.max if @opts[:align]
            value.each do |k, v|
              to_indented_strings(v, buf: buf, maxkeylength: maxkeylength, key: k, indent: indent + 1)
            end
          elsif value.is_a?(Array)
            buf << "#{indent_spaces}#{c(key.is_a?(Numeric) ? "[#{key}]" : "#{key}:")}" if key
            value.each_with_index do |v, i|
              to_indented_strings(v, buf: buf, maxkeylength: maxkeylength, key: i, indent: indent + 1)
            end
          elsif key
            buf << "#{indent_spaces}#{c(key.to_s.rjust(maxkeylength))}: #{c(value, :blue)}"
          else
            buf << "#{indent_spaces}#{c(value, :blue)}"
          end

          buf
        end
      end

      class JsonFormatter < Formatter
        self.id = "json"

        def setup
          @opts[:colorize] = false

          require "json"
        rescue LoadError
          warn c("The iparty JSON output formatter requires the json gem to be installed.", :red)
          warn c("Resolution:", :yellow)
          warn c("  gem install json", :blue)
          exit 1
        end

        def format_all ips, **kw, &to_data
          data = ips.to_h {|ip| [ip, to_data.call(ip)] }
          [JSON.pretty_generate(data)]
        end

        def format ip, **kw, &to_data
          JSON.pretty_generate to_data.call(ip)
        end
      end

      class StringFormatter < Formatter
        self.id = /%{/

        def format_all ips, base_index: 0, **kw, &to_data
          ips.map.with_index {|ip, index| format(ip, index: base_index + index, **kw, &to_data) }
        end

        def format ip, index: 0, **kw, &to_data
          data = to_data.call(ip)
          locals = { 1 => ip }
          fwd_hash = Hash.new do |_, key|
            dig_loose_value(data, key, locals) || (@app.opts[:debug] ? nil : "")
          end

          out = @opts[:argument] % fwd_hash
          out.empty? ? VOID_OUTPUT : out
        end

        def dig_loose_value data, key, locals = {}
          key_part, def_val = key.to_s.split("|", 2)
          chunks = key_part.split(".").map{ _1.match?(/\A-?\d+\z/) ? _1.to_i : _1.to_sym }

          return locals.fetch(chunks[0]) if chunks.length == 1 && locals.key?(chunks[0])

          dig_loose_value_in(data, chunks) || def_val
        end

        def dig_loose_value_in ptr, chunks
          return ptr if chunks.empty?
          return ptr unless ptr.is_a?(Hash) || ptr.is_a?(Array)

          dig_loose_value_in(ptr[chunks[0]], chunks[1..])
        end
      end
    end
  end
end
