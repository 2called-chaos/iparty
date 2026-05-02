# frozen_string_literal: true

require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ["--fail-level", "W"]
end

task default: %i[spec rubocop]
task ci: %i[early_simplecov fetch_mmdb_files default]

desc "load simplecov early"
task :early_simplecov do
  require "simplecov"
  SimpleCov.command_name "early"
end

desc "download mmdb files for testing"
task :fetch_mmdb_files do
  require "iparty"
  IParty.config.directory = Pathname.new(__dir__).join("spec", "cache")

  require "iparty/rake_task"
  IParty::RakeTask.new

  # always fetch one for coverage
  smallest = IParty.config.directory.join("GeoLite2-ASN.mmdb")
  smallest.unlink if smallest.exist?

  Rake::Task["iparty:fetch"].invoke

  # invalid file
  IParty.config.directory.join("GeoLite2-INVALID.mmdb").binwrite("INVALID")
end

# ---

desc "same as cop:html_open"
task cop: "cop:html_open"

namespace :cop do
  desc "Show worst offenders / worst files"
  task :worst do
    sh("rubocop -f autogenconf -f worst --fail-level W") {} # ignore non-zero exit code
  end

  desc "Create rubocop HTML report"
  task :html do
    sh("rubocop -f autogenconf -f html -o tmp/rubocop.html") {} # ignore non-zero exit code
  end

  desc "Create rubocop HTML report and open it"
  task :html_open do
    Rake::Task["cop:html"].invoke
    sh "open tmp/rubocop.html"
  end
end
