require "test_helper"

class Peak::Gem::GemspecTest < ActiveSupport::TestCase
  defaults = %i[required_ruby_version required_rubygems_version dependencies metadata].index_with(nil)
  GemspecShim = Data.define(*defaults.keys) { def metadata=(v); end }.new(**defaults)

  test "parsing old gemspecs" do
    assert_nil gemspec_with(required_ruby_version: nil).ruby
    assert_nil gemspec_with(required_rubygems_version: nil).rubygems

    spec = gemspec_with(dependencies: [["ruby-ajp", ">= 0.2.0"], ["rails", ">= 0.14"]])
    assert_equal [%w[ruby-ajp >= 0.2.0], %w[rails >= 0.14]], spec.requirement_triples
  end

  test "parsing with duplicated dependencies" do
    spec = gemspec_with dependencies: [
      Gem::Dependency.new("xml-simple", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("builder", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("mime-types", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("mail", Gem::Requirement.new([">= 2.2.5"]), :runtime),
      Gem::Dependency.new("xml-simple", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("builder", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("mime-types", Gem::Requirement.new([">= 0"]), :runtime)
    ]
    assert_equal [%w[xml-simple >= 0], %w[builder >= 0], %w[mime-types >= 0], %w[mail >= 2.2.5]], spec.requirement_triples

    spec = gemspec_with dependencies: [
      Gem::Dependency.new("rack", Gem::Requirement.new([">= 0.9.1"]), :runtime),
      Gem::Dependency.new("rack", Gem::Requirement.new([">= 0.9.1", "< 1.0"]), :runtime)
    ]
    assert_equal [%w[rack >= 0.9.1], %w[rack < 1.0]], spec.requirement_triples

    spec = gemspec_with dependencies: [
      Gem::Dependency.new("activesupport", Gem::Requirement.new([">= 3.0.8", "< 3.2.0"]), :runtime),
      Gem::Dependency.new("activesupport", Gem::Requirement.new([">= 3.0.8"]), :runtime),
    ]
    assert_equal [%w[activesupport >= 3.0.8], %w[activesupport < 3.2.0]], spec.requirement_triples
  end

  test "links drops unsafe URI schemes and keeps web links" do
    shim = Data.define(:homepage, :metadata)["javascript:alert(1)", {
      "source_code_uri" => "https://example.com/src",
      "bug_tracker_uri" => "javascript:alert(2)",
      "changelog_uri"   => "data:text/html,evil"
    }]

    spec = Peak::Gem::Gemspec.new(shim)
    assert_equal({ source_code: "https://example.com/src" }, spec.links)
  end

  test "ref format" do
    refute valid_ref?("1.0\n9")
    refute valid_ref?("1.0 0")
    refute valid_ref?("1.0.0-x86_64-linux")
    refute valid_ref?("v1")
    refute valid_ref?("")
    refute valid_ref?("1.0.0; rm -rf")

    assert valid_ref?("1.0.0")
    assert valid_ref?("0.9.1")
    assert valid_ref?("8.1.0.pre.1")
  end

  private
    delegate :valid_ref?, to: Peak::Gem::Gemspec

    def gemspec_with(**values)
      Peak::Gem::Gemspec.new GemspecShim.with(**values)
    end
end
