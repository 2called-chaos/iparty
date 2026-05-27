# frozen_string_literal: true

require "fileutils"

require_relative "max_mind/database"

module IParty
  class MaxMind
    class << self
      def db edition
        edition = "GeoLite2-#{edition}" if edition.is_a?(Symbol)
        file = IParty.config.directory.join("#{edition}.mmdb")
        return unless file.exist?

        if ctn = IParty.config.singletons
          if ctn.is_a?(Proc)
            ctn = ctn.call
          elsif ctn == true
            ctn = IParty.config.init_singletons!
          end

          return ctn.fetch(edition) if ctn.key?(edition)
        end

        Database.new(file, reader: IParty.config.eager_load ? EagerReader : LazyReader).tap do |dbi|
          ctn[edition] ||= dbi if ctn
        end
      end

      def lookup edition, *args, close: true, **kw
        return unless mmdb = db(edition)

        mmdb.lookup(*args, **kw).tap do
          mmdb.close if close && !IParty.config.singletons
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
          temp_dir.glob("*.mmdb").each do |file|
            Database.new(file, reader: LazyReader)
            FileUtils.mv(file, IParty.config.directory)
          rescue Database::InvalidFileFormatError
            warn "iparty: ignoring invalid mmdb file: #{file}"
          end
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

      def fetch_db_file_reason file, fetch_when = :always
        return fetch_when if fetch_when == :always
        return :missing unless file.exist?

        begin
          Database.new(file, reader: LazyReader)
        rescue Database::InvalidFileFormatError
          return :invalid
        end

        return unless fetch_when.is_a?(Numeric)

        ctime = file.ctime
        age = Time.now - ctime
        :expired unless fetch_when > age
      end

      def fetch_db_file! edition, fetch_when = :always, verbose: false
        target_file = IParty.config.directory.join("#{edition}.mmdb")
        return target_file unless reason = fetch_db_file_reason(target_file, fetch_when)

        with_transactional_update_directory do |temp_dir|
          warn "iparty: fetching #{reason}: #{target_file.basename}" if verbose
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
