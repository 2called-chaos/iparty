# frozen_string_literal: true

RSpec.describe IParty::Address do
  geo_methods = %w[asn geo_city geo_country geo].freeze

  let(:mmdb_directory) { IParty::GEM_ROOT.join("spec", "cache") }

  {
    "#geo (v4)" => "4.78.241.0",
    "#geo (v6)" => "2001:708:510:8:9a6:442c:f8e0:7133",
  }.each do |name, ip_address|
    describe name do
      subject(:ip) { IParty(ip_address) }

      context "when mmdb files are present" do
        around {|example| IParty.with_config(directory: mmdb_directory, &example) }

        it "exports" do
          expect(ip.country).to be_present
        end

        geo_methods.each do |meth|
          it "returns result for ##{meth}" do
            result = ip.send(meth)
            expect(result).to be_a IParty::MaxMind::Result
            expect(result).to be_present
          end
        end
      end

      context "when mmdb files are absent" do
        around {|example| IParty.with_config(directory: Pathname.new("void"), &example) }

        geo_methods.each do |meth|
          it "returns result for ##{meth}" do
            ip.send(meth) # double for coverage
            result = ip.send(meth)
            expect(result).to be_a IParty::MaxMind::Result
            expect(result).to_not be_present
          end
        end
      end
    end
  end
end
