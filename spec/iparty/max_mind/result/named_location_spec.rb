# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Result::NamedLocation do
  subject(:result) { described_class.new(raw_result) }

  context "with a result" do
    let(:raw_result) do
      {
        geoname_id: 6_252_001,
        iso_code: "US",
        is_in_european_union: false,
        names: {
          de: "USA",
          en: "United States",
          es: "Estados Unidos",
          fr: "États-Unis",
          ja: "アメリカ合衆国",
          ru: "США",
          "pt-BR": "Estados Unidos",
          "zh-CN": "美国",
        },
      }
    end

    it{ expect(result.geoname_id).to eq 6_252_001 }
    it{ expect(result.iso_code).to eq "US" }
    it{ expect(result.is_in_european_union).to be false }
    it{ expect(result.in_european_union?).to be false }

    describe "name" do
      it "defaults to english name" do
        expect(result.name).to eq "United States"
      end

      it "uses passed locale" do
        expect(result.name(:ja)).to eq "アメリカ合衆国"
      end

      it "uses fallback_locale" do
        expect(result.name(:zz, fallback_locale: :fr)).to eq "États-Unis"
      end

      it "skips fallback_locale" do
        expect(result.name(:zz, fallback_locale: false)).to be_nil
      end

      it "resorts to nil" do
        expect(result.name(:zz, fallback_locale: :yy)).to be_nil
      end
    end

    describe "inquiry" do
      it "inquires on iso_code" do
        expect(result.us?).to be true
        expect(result.de?).to be false
      end

      it "inquires on english underscored name" do
        expect(result.united_states?).to be true
        expect(result.germany?).to be false
      end

      it "implements method_missing" do
        expect(result.respond_to?(:united_states?)).to be true
        expect(result.respond_to?(:united_states)).to be false
      end

      it "raises through super" do
        expect{ result.foobar }.to raise_error NoMethodError
      end
    end

    describe "dynamic comparison" do
      it "compares integers against geoname_id" do
        expect(result).to eq 6_252_001
      end

      it "compares strings against english name" do
        expect(result).to eq "United States"
      end

      it "compares super" do
        expect(result).to eq(raw_result)
        expect(result).to_not eq([])
        expect(result).to_not eq({})
      end
    end
  end

  context "without a result" do
    let(:raw_result) { nil }

    it{ expect(result.geoname_id).to be_nil }
    it{ expect(result.code).to be_nil }
    it{ expect(result.is_in_european_union).to be_nil }
    it{ expect(result.in_european_union?).to be_nil }
    it{ expect(result.iso_code).to be_nil }
    it{ expect(result.name).to be_nil }

    describe "inquiry" do
      it "inquires on iso_code" do
        expect(result.us?).to be false
        expect(result.de?).to be false
      end

      it "inquires on english underscored name" do
        expect(result.united_states?).to be false
        expect(result.germany?).to be false
      end
    end
  end
end
