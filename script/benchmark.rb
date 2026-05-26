# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)

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

puts "RSS-before[#{ARGV.first}]: #{("%.2f MB" % (`ps -o rss= -p #{Process.pid}`.to_f / 1024))}" if ARGV.first
Benchmark.ips do |x|
  # Configure the number of seconds used during
  x.config(warmup: 10, time: 60)

  case ARGV.first
  when "uncached"
    x.report("uncached") do
      IParty("88.198.63.113").geo.city.name
    end
  when "singletons"
    IParty.config.singletons = true
    x.report("singletons") do
      IParty("88.198.63.113").geo.city.name
    end
  when "eager_load"
    IParty.config.eager_load = true
    IParty.config.singletons = true
    x.report("eager_load") do
      IParty("88.198.63.113").geo.city.name
    end
  else
    %w[uncached singletons eager_load].each do |which|
      puts `ruby #{$PROGRAM_NAME} #{which}`
    end
    exit
  end

  x.compare!
end
GC.start
puts "RSS-after[#{ARGV.first}]: #{("%.2f MB" % (`ps -o rss= -p #{Process.pid}`.to_f / 1024))}", nil
