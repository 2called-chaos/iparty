# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Database do
  each_reader_class do
    it "inspects without @data" do
      expect(city_db.inspect).to match(/<IParty::/)
      expect(country_db.inspect).to_not include "@data"
    end

    it "fails on invalid file" do
      expect{ invalid_db.lookup(ip) }.to raise_error(IParty::MaxMind::Database::InvalidFileFormatError)
    end

    it "closes handle" do
      expect(city_db).to_not be_closed
      city_db.close
      expect(city_db).to be_closed
      expect{ city_db.lookup("1.2.3.4") }.to raise_error(IOError)
    end

    context "with the ip 127.0.0.1" do
      let(:ip) { "127.0.0.1" }
      let(:lookup) { city_db.lookup(ip) }

      it "returns a MaxMind::Result" do
        expect(lookup).to be_a IParty::MaxMind::Result
      end

      it "doesn't find data" do
        expect(lookup.keys).to eq %i[network]
      end
    end

    context "with the ip 4.78.241.0" do
      let(:ip) { "4.78.241.0" }
      let(:lookup) { city_db.lookup(ip) }

      it "returns a MaxMind::Result" do
        expect(lookup).to be_a IParty::MaxMind::Result
      end

      it "finds data" do
        expect(lookup).to_not be_empty
      end

      it "returns San Francisco as the English name" do
        expect(lookup.city.name).to eq "San Francisco"
      end

      it "returns 37.7976 as the latitude" do
        expect(lookup.latitude).to eq 37.7976
        expect(lookup.location.latitude).to eq 37.7976
      end

      it "returns -122.3994 as the longitude" do
        expect(lookup.longitude).to eq(-122.3994)
        expect(lookup.location.longitude).to eq(-122.3994)
      end

      it "returns nil for is_anonymous_proxy/anonymous_proxy?" do
        expect(lookup.traits.is_anonymous_proxy).to be_nil
        expect(lookup.traits.anonymous_proxy?).to be_nil
      end

      it "returns nil for is_satellite_provider/satellite_provider?" do
        expect(lookup.traits.is_satellite_provider).to be_nil
        expect(lookup.traits.satellite_provider?).to be_nil
      end

      it "returns United States as the English country name" do
        expect(lookup.country.name).to eq "United States"
      end

      it "returns false for the is_in_european_union" do
        expect(lookup.is_in_european_union).to be_nil
        expect(lookup.in_european_union?).to be_nil
        expect(lookup.country.is_in_european_union).to be_nil
        expect(lookup.country.in_european_union?).to be_nil
      end

      it "returns US as the country iso code" do
        expect(lookup.country.iso_code).to eq "US"
      end

      it "returns 4.78.128.0/17 as network" do
        expect(lookup.network).to eq "4.78.240.0/21"
      end
    end

    context "with the ip 2001:708:510:8:9a6:442c:f8e0:7133" do
      let(:ip) { "2001:708:510:8:9a6:442c:f8e0:7133" }
      let(:lookup) { city_db.lookup(ip) }

      it "finds data" do
        expect(lookup).to_not be_empty
      end

      it "returns true for the is_in_european_union" do
        expect(lookup.country.is_in_european_union).to be true
      end

      it "returns FI as the country iso code" do
        expect(lookup.country.iso_code).to eq "FI"
      end

      it "returns 2001:708::/32 as network" do
        expect(lookup.network).to eq "2001:708:400::/39"
      end
    end

    context "with a Canadian ipv6" do
      let(:ip) { "2607:5300:60:72ba::" }

      it "finds data" do
        expect(city_db.lookup(ip)).to_not be_empty
      end

      it "returns false for is_in_european_union" do
        expect(country_db.lookup(ip).country.is_in_european_union).to be_falsey
      end

      it "returns CA as the country iso code" do
        expect(country_db.lookup(ip).country.iso_code).to eq "CA"
      end
    end

    context "with a German ipv6" do
      let(:ip) { "2a01:488:66:1000:2ea3:495e::1" }

      it "finds data" do
        expect(city_db.lookup(ip)).to_not be_empty
      end

      it "returns true for the is_in_european_union" do
        expect(country_db.lookup(ip).country.is_in_european_union).to be true
      end

      it "returns DE as the country iso code" do
        expect(country_db.lookup(ip).country.iso_code).to eq "DE"
      end
    end

    test_ips = [
      ["185.23.124.1", "SA"],
      ["178.72.254.1", "CZ"],
      ["95.153.177.210", "RU"],
      ["200.148.105.119", "BR"],
      ["195.59.71.43", "GB"],
      ["179.175.47.87", "BR"],
      ["202.67.40.50", "ID"],
    ]

    test_ips.each do |ip, iso|
      context "with test ip #{ip}" do
        it "returns a MaxMind::Result" do
          expect(city_db.lookup(ip)).to be_a IParty::MaxMind::Result
        end

        it "returns #{iso} as the country iso code" do
          expect(country_db.lookup(ip).country.iso_code).to eq iso
        end
      end
    end
  end
end
