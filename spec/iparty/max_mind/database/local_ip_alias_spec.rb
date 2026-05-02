# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Database do
  each_reader_class do
    describe "local_ip_alias" do
      let(:ip) { "127.0.0.1" }
      let(:local_ip_alias) { "4.78.241.0" }

      around {|example| IParty.with_config(local_ip_alias:, &example) }

      context "with city_db" do
        it "returns a MaxMind::Result" do
          expect(city_db.lookup(ip)).to be_a IParty::MaxMind::Result
        end

        it "finds data" do
          expect(city_db.lookup(ip)).to_not be_empty
        end

        it "returns Mountain View as the English name" do
          expect(city_db.lookup(ip).city.name).to eq "San Francisco"
        end

        it "returns -122.3994 as the longitude" do
          expect(city_db.lookup(ip).location.longitude).to eq(-122.3994)
        end

        it "returns nil for is_anonymous_proxy" do
          expect(city_db.lookup(ip).traits.is_anonymous_proxy).to be_nil
        end
      end

      context "with country_db" do
        it "returns United States as the English country name" do
          expect(country_db.lookup(ip).country.name).to eq "United States"
        end

        it "returns false for the is_in_european_union" do
          expect(country_db.lookup(ip).country.is_in_european_union).to be_nil
        end

        it "returns US as the country iso code" do
          expect(country_db.lookup(ip).country.iso_code).to eq "US"
        end
      end
    end
  end
end
