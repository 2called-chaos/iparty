# frozen_string_literal: true

require "iparty/cli/application"

RSpec.describe IParty::CLI::Application do
  around {|example| IParty.with_config(directory: mmdb_directory, &example) }

  let(:mmdb_directory) { IParty::GEM_ROOT.join("spec", "cache") }

  let(:app_env) { {} }
  let(:app_argv) { ["--no-rc", "--monochrome"] }
  let(:app_argf) { StringIO.new }
  let(:app) { described_class.new(env: app_env, argv: app_argv, argf: app_argf, mmdb_fetch_when: :missing) }

  context "with RC" do
    let(:app_env) { { "IPARTY_CFGDIR" => IParty::GEM_ROOT.join("spec", "data", "clirc") } }
    let(:app_argv) { ["--monochrome"] }

    it "initializes with rc" do
      expect(app.opts[:rspec_rc_loaded]).to be true
    end
  end

  context "with inaccessible RC" do
    let(:app_env) { { "IPARTY_CFGDIR" => IParty::GEM_ROOT.join("fail") } }
    let(:app_argv) { ["--monochrome"] }

    it { expect{ app }.to_not raise_error }
  end

  it "initializes without error" do
    expect{ app }.to_not raise_error
    expect(app.opts).to be_a Hash
  end

  it "dispatches help without args" do
    app.argv << "--no-monochrome"
    expect{ app.dispatch }.to output(/Usage:\e\[0m \e\[37miparty/).to_stdout
  end

  it "dispatches help with invalid arg" do
    app.argv << "--thisdoesnotexist"
    expect{ app.dispatch }.to output(/Usage: iparty/).to_stdout.and output("invalid option: --thisdoesnotexist\n").to_stderr
  end

  it "dispatches help (-h)" do
    app.argv << "-h"
    expect{ app.dispatch }.to_not output(/\e\[0m/).to_stdout
  end

  it "dispatches appinfo (-v)" do
    app.argv << "-v"
    expect{ app.dispatch }.to output(/# Runtime/).to_stdout
  end

  it "dispatches appinfo with debug (-v --debug)" do
    app.argv << "-v" << "--debug"
    IParty.with_config do |config|
      config.annotate "1.2.3.4", tags: %i[tag]
      expect{ app.dispatch }.to output(/# Available formatters/).to_stdout
    end
  end

  it "dispatches ipinfo for localhost" do
    app.argv << "127.0.0.0"
    expect{ app.dispatch }.to output("   type: ipv4[/32]\nnetwork: 127.0.0.0/8\n").to_stdout
  end

  it "reads from stdin" do
    app_argf.puts "4.78.241.0 2001:708:510:8:9a6:442c:f8e0:7133", "one.one.one.one"
    app_argf.rewind
    app.argv << "--stdin"
    expect{ app.dispatch }.to output(satisfy{|out| out.scan("network:").count == 6 && out.scan("=>").count == 6 }).to_stdout
  end

  it "dispatches ipinfo for arg" do
    app.argv << "4.78.241.0"
    expect{ app.dispatch }.to output(
      <<~OUT,
             type: ipv4[/32]
          network: 4.78.240.0/21 -- AS3356 Level 3 Parent, LLC
         location: North America / United States / 94111 San Francisco
        time_zone: America/Los_Angeles
          latlong: https://www.google.com/maps?q=37.797600,-122.399400
      OUT
    ).to_stdout
  end

  it "dispatches ipinfo for args" do
    app.argv << "4.78.241.0" << "2001:708:510:8:9a6:442c:f8e0:7133"
    expect{ app.dispatch }.to output(
      <<~OUT,
        =========> 4.78.241.0
             type: ipv4[/32]
          network: 4.78.240.0/21 -- AS3356 Level 3 Parent, LLC
         location: North America / United States / 94111 San Francisco
        time_zone: America/Los_Angeles
          latlong: https://www.google.com/maps?q=37.797600,-122.399400

        =========> 2001:708:510:8:9a6:442c:f8e0:7133
             type: ipv6[/128]
          network: 2001:708:400::/39 -- AS1741 Tieteen tietotekniikan keskus Oy
         location: Europe / Finland / 02150 Espoo
        time_zone: Europe/Helsinki
          latlong: https://www.google.com/maps?q=60.181600,24.836800
      OUT
    ).to_stdout
  end

  it "dispatches ipinfo --only" do
    app.argv << "-a" << "4.78.241.0" << "-o" << "country.geoname_id"
    expect{ app.dispatch }.to output("country:\n  geoname_id: 6252001\n").to_stdout
  end

  it "dispatches ipinfo --except" do
    app.argv << "-a" << "4.78.241.0" << "-e" << "cidr"
    expect{ app.dispatch }.to_not output(/cidr:/).to_stdout
  end

  describe "Resolv hostname lookup" do
    it "resolves hostname" do
      app.argv << "1.1.1.1" << "-r"
      expect{ app.dispatch }.to output(
        <<~OUT,
              type: ipv4[/32]
          hostname: one.one.one.one
           network: 1.1.1.0/24 -- AS13335 Cloudflare, Inc.
          location: Australia
        OUT
      ).to_stdout
    end
  end

  describe "Formatters" do
    it "formats nothing" do
      app.argv << "-f" << "off" << "4.78.241.0" << "one.one.one.one"
      expect{ app.dispatch }.to_not output.to_stdout
    end

    it "formats with json formatter" do
      app.argv << "-f" << "json" << "-o" << "location,time_zone" << "4.78.241.0" << "2001:708:510:8:9a6:442c:f8e0:7133"
      expect{ app.dispatch }.to output(
        <<~OUT,
          {
            "4.78.241.0": {
              "location": "North America / United States / 94111 San Francisco",
              "time_zone": "America/Los_Angeles"
            },
            "2001:708:510:8:9a6:442c:f8e0:7133": {
              "location": "Europe / Finland / 02150 Espoo",
              "time_zone": "Europe/Helsinki"
            }
          }
        OUT
      ).to_stdout
    end

    it "formats with string formatter" do
      app.argv << "4.78.241.0" << "2001:708:510:8:9a6:442c:f8e0:7133"
      app.argv << "-af" << "%{country.name} / %{subdivisions.-1.name} / %{city.name}"
      app.dispatch
      expect{ app.dispatch }.to output("United States / California / San Francisco\nFinland / Uusimaa / Espoo\n").to_stdout
    end
  end
end
