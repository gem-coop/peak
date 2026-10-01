require "test_helper"

class Peak::Gem::GemspecTest < ActiveSupport::TestCase
  defaults = %i[required_ruby_version required_rubygems_version dependencies].index_with(nil)
  GemspecShim = Data.define(*defaults.keys).new(**defaults)

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

  private
    def gemspec_with(**values)
      Peak::Gem::Gemspec.new GemspecShim.with(**values)
    end
end
