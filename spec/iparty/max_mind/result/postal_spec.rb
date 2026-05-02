# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Result::Postal do
  subject(:result) { described_class.new(raw_result) }

  context "with a result" do
    let(:raw_result) { { code: "94043" } }

    it{ expect(result.code).to eq "94043" }
  end

  context "without a result" do
    let(:raw_result) { nil }

    it{ expect(result.code).to be_nil }
  end
end
