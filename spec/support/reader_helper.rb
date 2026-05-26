# frozen_string_literal: true

module ReaderHelper
  def each_reader_class(&block)
    let(:mmdb_directory) { IPARTY_GEM_ROOT.join("spec", "cache") }
    let(:city_db) { IParty::MaxMind::Database.new(mmdb_directory.join("GeoLite2-City.mmdb"), reader: reader_class) }
    let(:country_db) { IParty::MaxMind::Database.new(mmdb_directory.join("GeoLite2-Country.mmdb"), reader: reader_class) }
    let(:invalid_db) { IParty::MaxMind::Database.new(mmdb_directory.join("GeoLite2-INVALID.mmdb"), reader: reader_class) }

    [
      ["EagerReader", IParty::MaxMind::EagerReader],
      ["LazyReader", IParty::MaxMind::LazyReader],
    ].each do |desc, klass|
      describe desc do
        let(:reader_class) { klass }

        class_exec(&block)
      end
    end
  end
end

RSpec.configure do |config|
  config.extend ReaderHelper
end
