# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Result::Subdivisions do
  subject(:result) { described_class.new(raw_result) }

  context "with multiple subdivisions" do
    let(:raw_result) do
      [
        {
          geoname_id: 5_037_779,
          iso_code: "MN",
          names: { en: "Minnesota" },
        },
        {
          geoname_id: 123,
          iso_code: "HP",
          names: { en: "Hennepin" },
        },
      ]
    end

    it "is a kind of Array" do
      expect(result).to be_a Array
    end

    it "inspects distinctively" do
      expect(result.inspect).to match(/<IParty::/)
    end

    describe "#presence" do
      it("implements blank?") { expect(result.blank?).to be false }
      it("implements present?") { expect(result.present?).to be true }
      it("implements presence") { expect(result.presence).to be_a IParty::MaxMind::Result::Subdivisions }
    end

    it "returns as many items as there are subdivisions passed in" do
      expect(result.length).to eq(raw_result.length)
    end

    it "only contains MaxMind::Result::NamedLocation" do
      expect(result).to all(be_a IParty::MaxMind::Result::NamedLocation)
    end

    describe "most_specific" do
      it "is a MaxMind::Result::NamedLocation" do
        expect(result.most_specific).to be_a IParty::MaxMind::Result::NamedLocation
      end

      it "is Hennepin subdivision" do
        expect(result.most_specific.name).to eq "Hennepin"
      end
    end
  end

  context "without a result" do
    let(:raw_result) { nil }

    it "is a kind of Array" do
      expect(result).to be_a Array
    end

    describe "#presence" do
      it("implements blank?") { expect(result.blank?).to be true }
      it("implements present?") { expect(result.present?).to be false }
      it("implements presence") { expect(result.presence).to be_nil }
    end

    it "is empty" do
      expect(result.length).to eq 0
    end

    %i[least_specific most_specific].each do |which_division|
      describe which_division.to_s do
        let(:division) { result.send(which_division) }

        it "is a kind of MaxMind::Result::NamedLocation" do
          expect(division).to be_a IParty::MaxMind::Result::NamedLocation
        end

        it "is an empty MaxMind::Result::NamedLocation" do
          expect(division.code).to be_nil
          expect(division.geoname_id).to be_nil
          expect(division.iso_code).to be_nil
          expect(division.name).to be_nil
        end
      end
    end
  end
end
