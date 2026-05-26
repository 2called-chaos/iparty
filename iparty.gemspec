# frozen_string_literal: true

require_relative "lib/iparty/version"

Gem::Specification.new do |spec|
  spec.name = "iparty"
  spec.version = IParty::VERSION
  spec.authors = ["Sven Pachnit"]
  spec.email = ["sven@bmonkeys.net"]

  spec.summary = "Makes (geo) IP fun again!"
  spec.description = "Makes (geo) IP fun again! Geo, v6 significance and more."
  spec.homepage = "https://github.com/2called-chaos/iparty"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ docs/ script/ spec/ Gemfile .gitignore .rspec .gitlab-ci.yml .rubocop.yml .ruby-version .simplecov])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "fileutils"
  spec.add_dependency "forwardable"
  spec.add_dependency "optparse"
  spec.add_dependency "tmpdir"
end
