# frozen_string_literal: true

require "fileutils"

require_relative "max_mind/low_memory_reader"
require_relative "max_mind/database"

module IParty
  class MaxMind
    class << self
      def db edition
        edition = "GeoLite2-#{edition}" if edition.is_a?(Symbol)
        file = IParty.config.directory.join("#{edition}.mmdb")
        return unless file.exist?

        if ctn = IParty.config.singletons
          ctn = ctn.call if ctn.is_a?(Proc)
          return ctn.fetch(edition) if ctn.key?(edition)
        end

        Database.new(file, reader: IParty.config.eager_load ? Database::DEFAULT_READER : Database::LOW_MEMORY_READER).tap do |dbi|
          ctn[edition] ||= dbi if ctn
        end
      end

      def with_transactional_update_directory
        temp_dir = IParty.config.directory.join(".updating")
        return yield(temp_dir) if @in_transaction

        begin
          @in_transaction = true
          temp_dir.mkpath
          yield(temp_dir)
        ensure
          @in_transaction = false
          temp_dir.glob("*.mmdb").each {|f| FileUtils.mv(f, IParty.config.directory) }
          FileUtils.rm_rf(temp_dir)
        end
      end

      def fetch_db_files! fetch_when = :always, verbose: false
        with_transactional_update_directory do
          IParty.config.editions.each do |edition|
            fetch_db_file!(edition, fetch_when, verbose: verbose)
          end
        end
      end

      def fetch_db_file? file, fetch_when = :always
        fetch_when != :missing || !file.exist?
      end

      def fetch_db_file! edition, fetch_when = :always, verbose: false
        target_file = IParty.config.directory.join("#{edition}.mmdb")
        return target_file unless fetch_db_file?(target_file, fetch_when)

        with_transactional_update_directory do |temp_dir|
          puts "fetching #{target_file.basename}" if verbose
          IParty.config.url_to_mmdb.call(
            IParty.config.mirror.gsub(":edition", edition),
            temp_dir,
            IParty.config,
          )
        end
      end
    end
  end
end
