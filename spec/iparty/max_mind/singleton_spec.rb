# frozen_string_literal: true

RSpec.describe IParty::MaxMind do
  let(:mmdb_directory) { IPARTY_GEM_ROOT.join("spec", "cache") }

  around {|example| IParty.with_config(directory: mmdb_directory, &example) }
  after { IParty.config.singletons = false }

  context "with global singletons" do
    it "populates" do
      IParty.config.singletons = true

      expect(IParty.config.singletons).to be_a Hash
      expect(IParty.config.singletons.keys).to eq %w[GeoLite2-ASN GeoLite2-Country GeoLite2-City]
    end

    it "uses proc" do
      ghash = {}
      IParty.config.singletons = -> { ghash }
      IParty.config.init_singletons!
      expect(IParty.config.singletons.call.keys).to eq %w[GeoLite2-ASN GeoLite2-Country GeoLite2-City]
    end
  end
end
