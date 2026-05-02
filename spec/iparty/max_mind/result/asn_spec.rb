# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Result::Asn do
  subject(:result) { described_class.new(raw_result) }

  let(:raw_result) do
    {
      autonomous_system_number: 24_940,
      autonomous_system_organization: "Hetzner Online GmbH",
      network: "88.198.0.0/16",
    }
  end

  describe "ASN data" do
    context "with a result" do
      it "is a MaxMind::Result" do
        expect(result).to be_a IParty::MaxMind::Result
      end

      it "has a number" do
        expect(result.number).to eq 24_940
        expect(result.autonomous_system_number).to eq 24_940
      end

      it "has an organization" do
        expect(result.organization).to eq "Hetzner Online GmbH"
        expect(result.autonomous_system_organization).to eq "Hetzner Online GmbH"
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it "is a MaxMind::Result" do
        expect(result).to be_a IParty::MaxMind::Result
      end

      it{ expect(result.number).to be_nil }
      it{ expect(result.autonomous_system_number).to be_nil }
      it{ expect(result.organization).to be_nil }
      it{ expect(result.autonomous_system_organization).to be_nil }
    end
  end
end
