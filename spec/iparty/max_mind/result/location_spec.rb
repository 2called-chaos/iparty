# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Result::Location do
  subject(:result) { described_class.new(raw_result) }

  context "with a result" do
    let(:raw_result) do
      {
        latitude: 37.419200000000004,
        longitude: -122.0574,
        metro_code: "807",
        time_zone: "America/Los_Angeles",
        accuracy_radius: 1000,
      }
    end

    it{ expect(result.latitude).to eq 37.419200000000004 }
    it{ expect(result.longitude).to eq(-122.0574) }
    it{ expect(result.metro_code).to eq "807" }
    it{ expect(result.time_zone).to eq "America/Los_Angeles" }
    it{ expect(result.accuracy_radius).to eq 1000 }
  end

  context "without a result" do
    let(:raw_result) { nil }

    it{ expect(result.latitude).to be_nil }
    it{ expect(result.longitude).to be_nil }
    it{ expect(result.metro_code).to be_nil }
    it{ expect(result.time_zone).to be_nil }
    it{ expect(result.accuracy_radius).to be_nil }
  end
end
