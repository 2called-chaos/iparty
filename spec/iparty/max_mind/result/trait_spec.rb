# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Result::Traits do
  subject(:result) { described_class.new(raw_result) }

  context "with an is_anonymous_proxy result" do
    let(:raw_result) { { is_anonymous_proxy: true } }

    it{ expect(result.is_anonymous_proxy).to be true }
    it{ expect(result.anonymous_proxy?).to be true }
    it{ expect(result.is_satellite_provider).to be_nil }
    it{ expect(result.satellite_provider?).to be_nil }
  end

  context "with an is_satellite_provider result" do
    let(:raw_result) { { is_satellite_provider: true } }

    it{ expect(result.is_anonymous_proxy).to be_nil }
    it{ expect(result.anonymous_proxy?).to be_nil }
    it{ expect(result.is_satellite_provider).to be true }
    it{ expect(result.satellite_provider?).to be true }
  end

  context "with an all traits result" do
    let(:raw_result) { { is_anonymous_proxy: true, is_satellite_provider: true } }

    it{ expect(result.is_anonymous_proxy).to be true }
    it{ expect(result.anonymous_proxy?).to be true }
    it{ expect(result.is_satellite_provider).to be true }
    it{ expect(result.satellite_provider?).to be true }
  end

  context "without a result" do
    let(:raw_result) { nil }

    it{ expect(result.is_anonymous_proxy).to be_nil }
    it{ expect(result.anonymous_proxy?).to be_nil }
    it{ expect(result.is_satellite_provider).to be_nil }
    it{ expect(result.satellite_provider?).to be_nil }
  end
end
