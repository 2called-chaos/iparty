# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)

require "benchmark"
require "bundler/inline"

gemfile do
  source "https://rubygems.org"

  gem "iparty", path: ROOT
  gem "benchmark-ips"
end

IParty.configure do |config|
  config.directory = Pathname.new(ROOT).join("spec", "cache")
end

IParty.fetch_db_files!(:missing, verbose: true)

# ------------------------------------------

pid = Process.pid
puts "RSS-before[#{pid}]: #{("%.2f MB" % (`ps -o rss= -p #{pid}`.to_f / 1024))}"

rt = Benchmark.realtime do
  IParty.configure do |config|
    # config.eager_load = true
    config.init_singletons!
  end
end
puts "RT-warmup:#{"%.4f" % rt}"
puts "RSS-warmup[#{pid}]: #{("%.2f MB" % (`ps -o rss= -p #{pid}`.to_f / 1024))}"

rt = Benchmark.realtime do
  100_000.times do
    IParty("88.198.63.113").city.name
  end
rescue Interrupt
end

puts "RT:#{"%.4f" % rt}"

puts "RSS-after[#{pid}]: #{("%.2f MB" % (`ps -o rss= -p #{pid}`.to_f / 1024))}"
