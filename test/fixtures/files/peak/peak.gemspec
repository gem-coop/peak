# frozen_string_literal: true

Gem::Specification.new do
  it.name = "peak"
  it.version = ENV["PEAK_VERSION"] || "0.1.0"
  it.authors = ["Peak Programmer"]
  it.email = ["peakprog@example.com"]

  it.summary = "The peak gem of them all."
  it.homepage = "https://github.com/gem-coop/peak"
  it.license = "MIT"
  it.required_ruby_version = ">= 4.0"
  it.required_rubygems_version = ">= 2.7"

  it.metadata["allowed_push_host"] = "http://peak.test"
  it.metadata["homepage_uri"]      = it.homepage
  it.metadata["documentation_uri"] = it.homepage
  it.metadata["source_code_uri"]   = it.homepage
  it.metadata["changelog_uri"]     = "#{it.homepage}/blob/main/CHANGELOG.md"
  it.metadata["bug_tracker_uri"]   = "#{it.homepage}/issues"
  it.metadata["mailing_list_uri"]  = it.homepage
  it.metadata["somewhere_custom_uri"]  = it.homepage
  it.metadata["somewhere_blank_uri"]  = ""

  it.bindir = "exe"
  it.executables = ["peak"]
  it.extensions = ["ext/extconf.rb"]
  it.platform = ENV["PEAK_PLATFORM"] || "ruby"

  it.files = []
  it.require_paths = ["lib"]

  it.add_dependency "oaken", ">= 0.9", "~> 1.0.0" # Do double to test multiple values
  if it.version >= Gem::Version.new("0.2.0")
    it.add_dependency "second_release_exclusive_ref", "= 2.0"
  end
end
