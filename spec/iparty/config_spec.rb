# frozen_string_literal: true

RSpec.describe IParty::Config do
  it "configures" do
    IParty.configure do |config|
      expect(config).to be_a IParty::Config
    end
  end

  it "returns merged config" do
    config = IParty.with_config(account_id: "test")
    expect(config.account_id).to eq "test"
  end

  it "build config without errors" do
    expect{ IParty.default_config }.to_not raise_error
  end

  describe "env variables" do
    it "reads account from env" do
      with_env("MAXMIND_ACCOUNT_ID" => "rspec") do
        expect(IParty.default_config.account_id).to eq "rspec"
      end
    end

    it "gives pathname for directory" do
      with_env("IPARTY_DIRECTORY" => "./") do
        expect(IParty.default_config.directory).to be_a Pathname
      end
    end

    it "casts true-ish values" do
      %w[1 true on yes].each do |v|
        with_env("IPARTY_EAGER_LOAD" => v) do
          expect(IParty.default_config.eager_load).to be true
        end
      end
    end

    it "casts false-ish values" do
      %w[0 false off no].each do |v|
        with_env("IPARTY_EAGER_LOAD" => v) do
          expect(IParty.default_config.eager_load).to be false
        end
      end
    end

    it "casts empty string to nil" do
      with_env("IPARTY_EAGER_LOAD" => "") do
        expect(IParty.default_config.eager_load).to be_nil
      end
    end
  end
end
