# frozen_string_literal: true

Gem::Specification.new do
  it.name = "peak"
  it.version = ENV["PEAK_VERSION"] || "0.1.0"
  it.authors = ["Peak Programmer"]
  it.email = ["peakprog@example.com"]

  it.summary = "The peak gem of them all."
  it.homepage = "http://peak.test"
  it.license = "MIT"
  it.required_ruby_version = ">= 4.0"
  it.required_rubygems_version = ">= 2.7"

  it.metadata["allowed_push_host"] = it.homepage
  it.metadata["homepage_uri"]      = it.homepage

  it.bindir = "exe"
  it.executables = ["peak"]

  it.files = []
  it.require_paths = ["lib"]

  it.add_dependency "oaken", ">= 0.9", "~> 1.0.1" # Do double to test multiple values
  if it.version >= Gem::Version.new("0.2.0")
    it.add_dependency "second_release_exclusive_ref", "= 2.0"
  end
end
