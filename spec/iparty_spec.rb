# frozen_string_literal: true

RSpec.describe IParty do
  it "has a version number" do
    expect(IParty::VERSION).to_not be_nil
  end

  describe "::normalize" do
    it "returns nil on blank input" do
      expect(IParty.normalize(nil)).to be_nil
      expect(IParty.normalize("  ")).to be_nil
    end

    it "strips input" do
      expect(IParty.normalize(" 1.2.3.4\t ").to_s).to eq "1.2.3.4"
    end

    it "accepts IPAddr / Address" do
      expect(IParty.normalize(IPAddr.new("1.2.3.4")).to_s).to eq "1.2.3.4"
      expect(IParty.normalize(IParty("1.2.3.4")).to_s).to eq "1.2.3.4"
    end

    it "normalizes insignificant address correctly" do
      ip = IParty.normalize("2606:4700:4700::1001", significant: false)
      ip2 = IParty.normalize(ip)
      expect(ip2.ipv6_significant).to be true
      expect(ip2.to_s).to eq ip.to_s(significant: true)
    end

    it "autodetects longs" do
      expect(IParty.normalize(123_456).to_s).to eq "0.1.226.64"
      expect(IParty.normalize((2**32) - 1).to_s).to eq "255.255.255.255"
      expect(IParty.normalize(2**32, significant: true).to_s).to eq "::1:0:0"
    end

    it "fails on bogus input" do
      expect{ IParty.normalize("yomama") }.to raise_error IPAddr::InvalidAddressError
      expect{ IParty.normalize({ yo: "mama" }) }.to raise_error IPAddr::InvalidAddressError
    end
  end

  describe "native normalization" do
    subject(:mapped_ip) { "::ffff:1.2.3.4" }

    it "unmaps ip" do
      expect(IParty.normalize(mapped_ip, native: true).to_s).to eq "1.2.3.4"
    end

    it "keeps mapped ip" do
      expect(IParty.normalize(mapped_ip).to_s).to eq "::ffff:1.2.3.4"
    end
  end

  describe "::classify" do
    it "classifies v4" do
      expect(IParty.classify("1.2.3.4")).to eq :ipv4
    end

    it "classifies v6" do
      expect(IParty.classify("::1")).to eq :ipv6
    end

    it "classifies invalid" do
      expect(IParty.classify("yomama")).to eq :invalid
    end
  end

  describe "::expand_hostnames" do
    context "with Resolv" do
      it "resolves valid" do
        expect(IParty.expand_hostnames("one.one.one.one").sort).to eq %w[1.0.0.1 1.1.1.1 2606:4700:4700::1001 2606:4700:4700::1111]
      end

      it "resolves invalid to empty array" do
        expect(IParty.expand_hostnames("INVALID").sort).to eq %w[]
      end
    end

    context "without Addrinfo" do
      before { hide_const("Resolv") }

      it "resolves valid" do
        expect(IParty.expand_hostnames("one.one.one.one", nil, "8.8.8.8").sort).to eq %w[1.0.0.1 1.1.1.1 2606:4700:4700::1001 2606:4700:4700::1111 8.8.8.8]
      end

      it "resolves invalid to empty array" do
        expect(IParty.expand_hostnames("INVALID").sort).to eq %w[]
      end
    end

    context "without nothing" do
      before do
        hide_const("Resolv")
        hide_const("Addrinfo")
      end

      it "fails" do
        expect { IParty.expand_hostnames("one.one.one.one") }.to raise_error(RuntimeError)
      end
    end
  end
end
