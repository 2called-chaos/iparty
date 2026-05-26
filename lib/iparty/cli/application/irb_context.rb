# frozen_string_literal: true

module IParty
  module CLI
    class Application
      class IrbContext
        attr_reader :app, :formatter

        def initialize(app)
          @app = app
        end

        def to_s
          "IParty::CLI"
        end

        def help
          puts "app         # application reference"
          puts "exit        # exit IRB"
          puts "ip *ips     # show summary for IPs"
        end

        def ip *ips
          addresses = IParty.expand_hostnames(ips)
          @app.out << if addresses.length > 1
            app.formatter.format_all(addresses){|ip| app.ip_to_data(ip, colorize: app.formatter.colorize?) }
          else
            [app.formatter.format(addresses[0]){|ip| app.ip_to_data(ip, colorize: app.formatter.colorize?) }]
          end

          nil
        end

        def start
          help
          binding.irb(show_code: false) # rubocop:disable Lint/Debugger -- no comment
        end
      end
    end
  end
end
