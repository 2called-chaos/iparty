# frozen_string_literal: true

module IParty
  module CLI
    class Application
      module Appinfo
        def appinfo_runtime pad: 20
          puts c("#{"".rjust(pad + 2)}# Runtime", :magenta)
          puts c("#{"IParty".rjust(pad)}: #{c IParty::VERSION, :blue}")
          puts c("#{"Ruby".rjust(pad)}: #{c RUBY_DESCRIPTION, :blue}")
        end

        def appinfo_cli_opts pad: 20
          puts c("#{"".rjust(pad + 2)}# CLI options", :magenta)
          @opts.each_pair do |key, value|
            puts c("#{key.to_s.rjust(pad)}: #{c value.inspect, default_options[key] == value ? :cyan : :blue}")
          end
        end

        def appinfo_cli_config pad: 20
          path_inaccessible = c(" (inaccessible)", :red) if !@config_path.directory? || !@config_path.readable?
          file_inaccessible = c(" (inaccessible)", :red) if !@config_file.exist? || !@config_file.readable?
          file_disabled = c(" (disabled)", :red) if @rc_disabled

          puts c("#{"".rjust(pad + 2)}# CLI config", :magenta)
          puts c("#{"config_path".rjust(pad)}: #{c @config_path.inspect, :blue}#{path_inaccessible}")
          puts c("#{"config_file".rjust(pad)}: #{c @config_file.inspect, :blue}#{file_disabled || file_inaccessible}")
        end

        def appinfo_iparty_config pad: 20
          puts c("#{"".rjust(pad + 2)}# IParty.config", :magenta)
          IParty.config.each_pair do |key, value|
            if key == :annotations && value
              puts c("#{key.to_s.rjust(pad)}:")
              value.each do |ipp, adata|
                puts c("  #{"".rjust(pad)}#{ipp.to_cidr}: #{c adata.inspect, :blue}")
              end
            else
              puts c("#{key.to_s.rjust(pad)}: #{c value.inspect, :blue}")
            end
          end
        end

        def appinfo_mmdb_status pad: 20
          puts c("#{"".rjust(pad + 2)}# MMDB file status", :magenta)
          IParty.config.editions.map do |edition|
            file = IParty.config.directory.join("#{edition}.mmdb")
            reason = IParty::MaxMind.fetch_db_file_reason(file, @opts[:mmdb_fetch_when])

            status = if file.exist?
              ctime = file.ctime
              age = (Time.now - ctime)
              days = (age / (60 * 60 * 24)).floor
              hours = ((age / (60 * 60)) % 24).floor
              minutes = ((age / 60) % 60).floor
              age_string = [
                ("#{days}d" if days > 0),
                ("%02d:%02d" % [hours, minutes] if hours > 0 || minutes > 0),
              ].compact.join(" ")
              age_string = "#{age.floor}s" if age_string.empty?

              if reason
                "#{c(reason.upcase, :red)} #{c("[age: #{age_string}, ctime: #{ctime}]", :black)} #{file}"
              else
                "#{c("OK", :green)} #{c("[age: #{age_string}, ctime: #{ctime}]", :black)} #{file}"
              end
            else
              "#{c("MISSING", :red)} #{file}"
            end

            puts c("#{edition.to_s.rjust(pad)}: #{status}")
            !reason
          end.all?
        end

        def appinfo_formatters pad: 20
          pad = -2 if pad.zero?

          puts c("#{"".rjust(pad + 2)}# Available formatters", :magenta)
          CLI::Formatter.descendants.each do |fmt|
            name = fmt.to_s
            source_location = begin
              if name.start_with?("#<Class:")
                rest = name.split("::", 2)[1]
                name = c("<IPARTYRC> ", :red) + c(rest, :blue)
                singleton_class.const_source_location(rest) if singleton_class.const_defined?(rest)
              else
                Object.const_source_location(name)
              end
            rescue StandardError => ex
              ["UNKNOWN(#{ex.class}: #{ex.message})", 0]
            end || ["UNKNOWN", 0]

            puts [
              c("#{"".rjust(pad)}* "),
              c(name, :blue),
              c("(", :black),
              c(fmt.id.inspect, :green),
              c(")", :black),
              c(" in #{source_location.join(":")}", :black),
            ].join
          end
        end
      end
    end
  end
end
