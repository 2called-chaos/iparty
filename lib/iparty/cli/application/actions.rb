# frozen_string_literal: true

module IParty
  module CLI
    class Application
      module Actions
        # via --irb/-d irb
        def dispatch_irb
          IrbContext.new(self).start
        end

        # via -h/--help
        def dispatch_help
          help_text = colorized_help_text
          help_text = help_text.map{ decolorize(_1) } unless @opts[:colorize]

          puts help_text, nil, c("The current config directory is #{c @config_path, :magenta}")
        end

        # via -v/--version
        def dispatch_appinfo pad: 20
          parts = if @opts[:debug]
            %i[runtime cli_opts cli_config actions formatters iparty_config mmdb_status]
          else
            %i[runtime cli_config mmdb_status]
          end

          parts.each_with_index do |imeth, i|
            puts unless i.zero?
            send(:"appinfo_#{imeth}", pad: pad)
          end
        end

        def dispatch_info use_argf: read_from_stdin?
          return dispatch_help if @argv.empty? && !use_argf

          ensure_mmdb_files!

          if use_argf
            each_line_in_argf_as_addresses do |addresses, index|
              out << formatter.format_all(addresses, base_index: index){|ip| ip_to_data(ip, colorize: formatter.colorize?) }
            end
          else
            addresses = IParty.expand_hostnames(@argv)

            out << if addresses.length > 1
              formatter.format_all(addresses){|ip| ip_to_data(ip, colorize: formatter.colorize?) }
            else
              formatter.format(addresses[0]){|ip| ip_to_data(ip, colorize: formatter.colorize?) }
            end
          end
        end
      end
    end
  end
end
