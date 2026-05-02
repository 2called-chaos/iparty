# frozen_string_literal: true

# rubocop:disable Style/NumericLiterals
RSpec.describe IParty::Address do
  describe "v4 ip" do
    subject(:ip) { IParty("1.2.3.4") }

    it "returns as long" do
      expect(ip.to_i).to eq 16909060
    end

    it "detects ranges" do
      expect(ip.range?).to be false
    end

    it "calculates network size" do
      expect(ip.size).to eq 1
    end

    it "ignores default prefix" do
      expect(ip.to_cidr).to eq "1.2.3.4"
    end

    it "includes default prefix" do
      expect(ip.to_cidr(default_masks: true)).to eq "1.2.3.4/32"
    end
  end

  describe "v4 range" do
    subject(:range) { IParty("1.2.3.4/24") }

    it "returns range as longs" do
      expect(range.to_long_range).to eq [16909056, 16909311]
    end

    it "detects ranges" do
      expect(range.range?).to be true
    end

    it "calculates network size" do
      expect(range.size).to eq 256
    end

    it "includes prefix" do
      expect(range.to_cidr).to eq "1.2.3.0/24"
    end
  end

  describe "v6 ip (insignificant)" do
    subject(:ip) { IParty("2001:9e8:4aa4:9700:840a:f1ad:2838:f58d", significant: false) }

    it "returns as long" do
      expect(ip.to_i).to eq 2306135377479767808
    end

    it "detects ranges" do
      expect(ip.range?).to be false
    end

    it "calculates network size" do
      expect(ip.size).to eq 1
    end

    it "drops upper bits" do
      expect(ip.to_cidr).to eq "2001:9e8:4aa4:9700::/64"
    end

    it "expands v6" do
      expect(ip.to_cidr(expand_v6: true)).to eq "2001:09e8:4aa4:9700:0000:0000:0000:0000/64"
    end
  end

  describe "v6 ip (significant)" do
    subject(:ip) { IParty("2001:9e8:4aa4:9700:840a:f1ad:2838:f58d") }

    it "returns as long" do
      expect(ip.to_i).to eq 42540689107696846582960424128251229581
    end

    it "detects ranges" do
      expect(ip.range?).to be false
    end

    it "calculates network size" do
      expect(ip.size).to eq 1
    end

    it "keeps upper bits" do
      expect(ip.to_cidr).to eq "2001:9e8:4aa4:9700:840a:f1ad:2838:f58d"
    end

    it "expands v6" do
      expect(ip.to_cidr(expand_v6: true)).to eq "2001:09e8:4aa4:9700:840a:f1ad:2838:f58d"
    end

    it "includes default prefix (significant)" do
      expect(ip.to_cidr(default_masks: true)).to eq "2001:9e8:4aa4:9700:840a:f1ad:2838:f58d/128"
    end
  end

  describe "v6 range (insignificant)" do
    subject(:range) { IParty("2001:9e8:4aa4:9700:840a:f1ad:2838:f58d/42", significant: false) }

    it "returns range as longs" do
      expect(range.to_long_range).to eq [2306135377477369856, 2306135377481564159]
    end

    it "detects ranges" do
      expect(range.range?).to be true
    end

    it "calculates network size" do
      expect(range.size).to eq 2**22
    end

    it "includes prefix" do
      expect(range.to_cidr).to eq "2001:9e8:4a80::/42"
    end
  end

  describe "v6 range (significant)" do
    subject(:range) { IParty("2001:9e8:4aa4:9700:840a:f1ad:2838:f58d/42") }

    it "returns range as longs" do
      expect(range.to_long_range).to eq [42540689107652612166600701272754487296, 42540689107729983419056037539935682559]
    end

    it "detects ranges" do
      expect(range.range?).to be true
    end

    it "calculates network size" do
      expect(range.size).to eq 2**86
    end

    it "includes prefix" do
      expect(range.to_cidr).to eq "2001:9e8:4a80::/42"
    end
  end

  describe "v6 significance cast" do
    it "casts to_significant" do
      ip = IParty("::1", significant: false)
      expect(ip.ipv6_significant).to be false
      ip = ip.to_significant
      expect(ip.ipv6_significant).to be true
    end

    it "casts to_insignificant" do
      ip = IParty("::1", significant: true)
      expect(ip.ipv6_significant).to be true
      ip = ip.to_insignificant
      expect(ip.ipv6_significant).to be false
    end
  end
end
# rubocop:enable Style/NumericLiterals
