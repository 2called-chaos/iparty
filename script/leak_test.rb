# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)

require "bundler/inline"

gemfile do
  source "https://rubygems.org"

  gem "iparty", path: ROOT
end

IParty.configure do |config|
  IParty.config.directory = Pathname.new(ROOT).join("spec", "cache")
end

# ------------------------------------------

# GC.disable
puts "PID:#{Process.pid}"

i = 0
loop do
  IParty("4.78.241.0").geo
  refs = ObjectSpace.each_object(File)
  print "\r\033[2K#{i += 1} calls -- #{refs.count} references, #{refs.count(&:closed?)} closed"
  sleep 0.01
end
