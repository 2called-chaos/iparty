# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Result::Geo do
  subject(:result) { described_class.new(raw_result) }

  let(:raw_result) do
    {
      city: {
        geoname_id: 5_375_480,
        names: {
          de: "Mountain View",
          en: "Mountain View",
          fr: "Mountain View",
          ru: "Маунтин-Вью",
          "zh-CN": "芒廷维尤",
        },
      },
      continent: {
        code: "NA",
        geoname_id: 6_255_149,
        names: {
          de: "Nordamerika",
          en: "North America",
          es: "Norteamérica",
          fr: "Amérique du Nord",
          ja: "北アメリカ",
          ru: "Северная Америка",
          "pt-BR": "América do Norte",
          "zh-CN": "北美洲",
        },
      },
      country: {
        geoname_id: 6_252_001,
        iso_code: "US",
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
      },
      location: {
        latitude: 37.419200000000004,
        longitude: -122.0574,
        metro_code: "807",
        time_zone: "America/Los_Angeles",
      },
      postal: {
        code: "94043",
      },
      registered_country: {
        geoname_id: 6_252_001,
        iso_code: "US",
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
      },
      represented_country: {
        geoname_id: 6_252_001,
        iso_code: "US",
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
      },
      traits: {
        is_satellite_provider: true,
      },
      subdivisions: [
        {
          geoname_id: 5_332_921,
          iso_code: "CA",
          names: {
            de: "Kalifornien",
            en: "California",
            es: "California",
            fr: "Californie",
            ja: "カリフォルニア州",
            ru: "Калифорния",
            "pt-BR": "Califórnia",
            "zh-CN": "加利福尼亚州",
          },
        },
      ],
      connection_type: "Dialup",
    }
  end

  it "is kind of a hash" do
    expect(result).to be_a Hash
    expect(result[:city]).to eq raw_result[:city]
    expect(result.dig(:city, :name)).to be_nil
    expect(result.dig(:city, :names, :en)).to eq "Mountain View"
  end

  it "inspects distinctively" do
    expect(result.inspect).to match(/<IParty::/)
  end

  describe "#presence" do
    context "with a result" do
      it("implements blank?") { expect(result.blank?).to be false }
      it("implements present?") { expect(result.present?).to be true }
      it("implements presence") { expect(result.presence).to be_a IParty::MaxMind::Result }
    end

    context "without a result" do
      let(:raw_result) { nil }

      it("implements blank?") { expect(result.blank?).to be true }
      it("implements present?") { expect(result.present?).to be false }
      it("implements presence") { expect(result.presence).to be_nil }
    end
  end

  %i[continent country city registered_country represented_country].each do |named_loc|
    describe "##{named_loc}" do
      subject(:loc) { result.send(named_loc) }

      loc_name_desc = named_loc.to_s.split("_").last.capitalize
      let(:loc_name) { named_loc.to_s.split("_").last.capitalize }

      context "with a result" do
        it "is a MaxMind::Result::NamedLocation/#{loc_name_desc}" do
          expect(loc).to be_a IParty::MaxMind::Result::NamedLocation
          expect(loc.class.name).to eq "IParty::MaxMind::Result::#{loc_name}"
        end
      end

      context "without a result" do
        let(:raw_result) { nil }

        it "is a MaxMind::Result::NamedLocation/#{loc_name_desc}" do
          expect(loc).to be_a IParty::MaxMind::Result::NamedLocation
          expect(loc.class.name).to eq "IParty::MaxMind::Result::#{loc_name}"
        end
      end
    end
  end

  describe "#location" do
    context "with a result" do
      it "is a MaxMind::Result::Location" do
        expect(result.location).to be_a IParty::MaxMind::Result::Location
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it "is a MaxMind::Result::Location" do
        expect(result.location).to be_a IParty::MaxMind::Result::Location
      end
    end
  end

  describe "#postal" do
    context "with a result" do
      it "is a MaxMind::Result::Postal" do
        expect(result.postal).to be_a IParty::MaxMind::Result::Postal
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it "is a MaxMind::Result::Postal" do
        expect(result.postal).to be_a IParty::MaxMind::Result::Postal
      end
    end
  end

  describe "#traits" do
    context "with a result" do
      it "is a MaxMind::Result::Traits" do
        expect(result.traits).to be_a IParty::MaxMind::Result::Traits
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it "is a MaxMind::Result::Traits" do
        expect(result.traits).to be_a IParty::MaxMind::Result::Traits
      end
    end
  end

  describe "#subdivisions" do
    context "with a result" do
      it "is a kind of Array" do
        expect(result.subdivisions).to be_a Array
      end

      it "returns as many results as there are subdivisions passed in" do
        expect(result.subdivisions.length).to eq raw_result[:subdivisions].length
      end

      it "only contains MaxMind::Result::Subdivision" do
        expect(result.subdivisions).to all(be_a IParty::MaxMind::Result::Subdivision)
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it "is a kind of Array" do
        expect(result.subdivisions).to be_a Array
      end

      it "is empty" do
        expect(result.subdivisions).to be_empty
        expect(result.subdivisions).to be_blank
        expect(result.subdivisions.presence).to be_nil
      end
    end

    describe "#connection_type" do
      context "with a result" do
        it "returns a String representation of connection type" do
          expect(result.connection_type).to eq "Dialup"
        end
      end

      context "without a result" do
        let(:raw_result) { nil }

        it{ expect(result.connection_type).to be_nil }
      end
    end

    describe "shortcut accessors" do
      context "with a result" do
        it{ expect(result.accuracy_radius).to eq result.location.accuracy_radius }
        it{ expect(result.metro_code).to eq result.location.metro_code }
        it{ expect(result.time_zone).to eq result.location.time_zone }
        it{ expect(result.zip).to eq result.postal.code }
      end

      context "without a result" do
        let(:raw_result) { nil }

        it{ expect(result.accuracy_radius).to eq result.location.accuracy_radius }
        it{ expect(result.metro_code).to eq result.location.metro_code }
        it{ expect(result.time_zone).to eq result.location.time_zone }
        it{ expect(result.zip).to eq result.postal.code }
      end
    end
  end
end
