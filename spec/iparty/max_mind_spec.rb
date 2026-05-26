# frozen_string_literal: true

RSpec.describe IParty::MaxMind do
  let(:mmdb_directory) { IParty::GEM_ROOT.join("spec", "cache") }

  around {|example| IParty.with_config(directory: mmdb_directory, &example) }

  describe "::db" do
    it "returns nil on missing file" do
      expect(IParty::MaxMind.db(:yomama)).to be_nil
    end

    it "returns database with symbol" do
      expect(IParty::MaxMind.db(:Country)).to be_a IParty::MaxMind::Database
    end

    it "returns database with string" do
      expect(IParty::MaxMind.db("GeoLite2-Country")).to be_a IParty::MaxMind::Database
    end

    it "uses lazy reader" do
      IParty.with_config(eager_load: false) do
        expect(IParty::MaxMind.db("GeoLite2-Country").instance_variable_get(:@data)).to be_a IParty::MaxMind::LazyReader
      end
    end

    it "uses eager reader" do
      IParty.with_config(eager_load: true) do
        expect(IParty::MaxMind.db("GeoLite2-Country").instance_variable_get(:@data)).to be_a IParty::MaxMind::EagerReader
      end
    end
  end
end
