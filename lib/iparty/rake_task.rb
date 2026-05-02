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
      define
    end

    def define
      namespace(name) do
        desc "Fetches missing geoip mmdb-files"
        task :fetch do
          Rake.application.lookup("environment")&.invoke

          IParty::MaxMind.fetch_db_files!(:missing, verbose: @verbose)
        end

        desc "Updates geoip mmdb-files"
        task :update do
          Rake.application.lookup("environment")&.invoke

          IParty::MaxMind.fetch_db_files!(verbose: @verbose)
        end

        desc "Shows effective IParty config (including license_key)"
        task :config do |task, args|
          Rake.application.lookup("environment")&.invoke

          case args.extras.first
          when "json"
            require "json"
            puts JSON.pretty_generate(IParty.config.to_h)
          when "inspect"
            puts IParty.config.inspect
          else
            IParty.config.each_pair do |key, value|
              puts "#{key.to_s.rjust(16)}: #{value.inspect}"
            end
          end
        end
      end
    end
  end
end
