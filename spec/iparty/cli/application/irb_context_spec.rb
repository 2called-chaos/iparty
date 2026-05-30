# frozen_string_literal: true

require "iparty/cli/application"

RSpec.describe IParty::CLI::Application::IrbContext do
  subject(:irb_ctx) { described_class.new(app) }

  around {|example| IParty.with_config(directory: mmdb_directory, &example) }

  let(:mmdb_directory) { IParty::GEM_ROOT.join("spec", "cache") }

  let(:app_env) { {} }
  let(:app_argv) { ["--no-rc", "-m"] }
  let(:app_argf) { [] }
  let(:app) { IParty::CLI::Application.new(env: app_env, argv: app_argv, argf: app_argf, &:parse_options!) }

  it "prints help" do
    irb_ctx.to_s
    expect{ irb_ctx.help }.to output(/# exit IRB/).to_stdout
  end

  it "prints single ip" do
    expect{ irb_ctx.ip("4.78.241.0") }.to output(satisfy{|out| out.scan("network:").one? && !out.include?("=>") }).to_stdout
  end

  it "prints multi with hostname" do
    expect do
      irb_ctx.ip("4.78.241.0", "one.one.one.one", "2001:708:510:8:9a6:442c:f8e0:7133")
    end.to output(satisfy{|out| out.scan("network:").count == 6 && out.scan("=>").count == 6 }).to_stdout
  end
end
