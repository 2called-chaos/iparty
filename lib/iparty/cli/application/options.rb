# frozen_string_literal: true

module IParty
  module CLI
    class Application
      module Options
        def default_options
          {
            debug: @argv.include?("--debug"),
            stdin: false,        # --stdin
            colorize: true,      # -m
            summarize: true,     # -a
            resolve: false,      # -r
            action: :info,       # -d
            formatter: "pretty", # -f
            lang: "en",          # -l
            only: [],            # -o
            except: [],          # -e

            # format latlong when summarizing (--no-a)
            fmt_latlong: "https://www.google.com/maps?q=%f,%f",

            # refresh stale mmdb files (:always, :missing, maxAge in seconds as Numeric)
            mmdb_fetch_when: 14 * 24 * 60 * 60, # 14.days
          }
        end

        def loadrc
          if @rc_disabled
            puts "[iparty-debug] skipping rc (disabled)" if @opts[:debug]
            return
          end

          unless @config_file.exist? && @config_file.readable?
            puts "[iparty-debug] skipping rc (inaccessible)" if @opts[:debug]
            return
          end

          puts "[iparty-debug] eval'ing rc #{@config_file}" if @opts[:debug]
          instance_eval @config_file.read(encoding: "utf-8"), @config_file.to_s
        end

        def require_resolv
          require "resolv"
        rescue LoadError
          warn c("This iparty feature requires the resolv gem to be installed.", :red)
          warn c("Resolution:", :yellow)
          warn c("  gem install resolv", :blue)
          exit 1
        end

        # rubocop:disable Layout/SpaceInsideParens, Metrics/AbcSize -- readability
        def init_optparse
          OptionParser.new do |opts|
            opts.summary_width = 38
            opts.banner = "Usage: iparty <IP|host...> [options]"

            expression_help = [
              c("** matches .*", :cyan),
              c(" * matches [^.]*", :cyan),
            ]

            opts.separator("\n# Application options")
            opts.on("-a", "--[no-]all", "full non-summarized output") {|v| @opts[:summarize] = !v }
            opts.on("-f", "--format <FORMATTER>", String, "formatter (pretty|json|off) or template string [default: #{@opts[:formatter]}]") {|v| @opts[:formatter] = v }
            opts.on("-l", "--language <LANG>", String, "limit output to language (or all) [default: #{@opts[:lang]}]") {|v| @opts[:lang] = v }
            opts.on("-r", "--[no-]resolve", "resolve hosts and include hostnames in data (requires resolv)") {|v| @opts[:resolv] = v }
            opts.on("-o", "--only   key,deep.key,*country*", Array, "list of key expressions (grep on full key)") {|v| @opts[:only] += v }
            opts.on("-e", "--except key,deep.key,sub*", Array, "list of key expressions (grep_v on full key)", *expression_help) {|v| @opts[:except] += v }
            opts.on(      "--[no-]stdin", "read from stdin (space/line separated IPs or hosts)") {|v| @opts[:stdin] = v }

            opts.separator("\n# (Custom) actions")
            opts.on("-d", "--dispatch ACTION", String, "Dispatch given action, you may add your own") {|v| @opts[:action] = v.to_sym }
            opts.on(      "--irb", "IRB repl with iparty context and helpers") { @opts[:action] = :irb }

            opts.separator("\n# MMDB actions")
            opts.on(      "--mmdb-status", "Show mmdb file status") { exit(appinfo_mmdb_status ? 0 : 1) }
            opts.on(      "--mmdb-fetch", "Fetch missing mmdb-editions") { ensure_mmdb_files! }
            opts.on(      "--mmdb-update", "Update all mmdb-editions") { ensure_mmdb_files!(:always) }

            opts.separator("\n# General options")
            opts.on("-h", "--help", "Shows this help") { @opts[:action] = :help }
            opts.on("-v", "--version", "Shows version and mmdb info (and config with --debug)") { @opts[:action] = :appinfo }
            opts.on("-m", "--[no-]monochrome", "Don't or do colorize output") {|v| @opts[:colorize] = !v }
            opts.on(      "--[no-]debug", "Enable debug, raise exceptions and print config with -v") {|v| @opts[:debug] = v }
            opts.on(      "--no-rc", "Do not eval config.rb")
          end
        end
        # rubocop:enable Layout/SpaceInsideParens, Metrics/AbcSize

        def parse_options!
          return @opts if @options_parsed

          @options_parsed = true
          @optparse.parse!(@argv)
          require_resolv if @opts[:resolv]
          @opts
        rescue OptionParser::ParseError => ex
          puts colorized_help_text, nil
          @opts[:debug] ? raise(ex) : abort(c(ex.message, :red))
        end

        def colorized_help_text
          @optparse.to_s.split("\n").map do |line|
            if line.start_with?("Usage:")
              words = line.split
              [
                colorize(words[0]),
                colorize(words[1], :white),
                colorize(words[2], :yellow),
                colorize(words[3..].join(" "), :cyan),
              ].join(" ")
            elsif line.start_with?("#")
              colorize(line, :blue)
            elsif line.strip.start_with?("-")
              summary_width = @optparse.summary_indent.length + @optparse.summary_width
              optstr = line[...summary_width]
              optdesc = line[summary_width..]
              optdesc&.gsub!(/(\[default: [^\]]+\])/){ colorize(_1, :black) }

              [
                colorize(optstr, :cyan),
                colorize(optdesc),
              ].join
            else
              colorize(line)
            end
          end
        end
      end
    end
  end
end
