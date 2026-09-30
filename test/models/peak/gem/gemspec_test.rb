require "test_helper"

class Peak::Gem::GemspecTest < ActiveSupport::TestCase
  test "parsing" do
    inner = Object.new
    def inner.required_ruby_version = nil
    def inner.required_rubygems_version = nil
    def inner.dependencies = [["ruby-ajp", ">= 0.2.0"], ["rails", ">= 0.14"]]

    spec = Peak::Gem::Gemspec.new inner
    assert_nil spec.ruby
    assert_nil spec.rubygems
    assert_equal [%w[ruby-ajp >= 0.2.0], %w[rails >= 0.14]], spec.requirement_triples.map { [_1, _2, _3.to_s] }
  end

  test "parsing with duplicated dependencies" do
    inner = Object.new
    def inner.dependencies = [
      Gem::Dependency.new("xml-simple", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("builder", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("mime-types", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("mail", Gem::Requirement.new([">= 2.2.5"]), :runtime),
      Gem::Dependency.new("shoulda-context", Gem::Requirement.new([">= 0"]), :development),
      Gem::Dependency.new("bundler", Gem::Requirement.new(["~> 1.0.0"]), :development),
      Gem::Dependency.new("jeweler", Gem::Requirement.new(["~> 1.5.2"]), :development),
      Gem::Dependency.new("rcov", Gem::Requirement.new([">= 0"]), :development),
      Gem::Dependency.new("flexmock", Gem::Requirement.new(["~> 0.8.11"]), :development),
      Gem::Dependency.new("xml-simple", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("builder", Gem::Requirement.new([">= 0"]), :runtime),
      Gem::Dependency.new("mime-types", Gem::Requirement.new([">= 0"]), :runtime)
    ]

    triples = Peak::Gem::Gemspec.new(inner).requirement_triples
    assert_equal [%w[xml-simple >= 0], %w[builder >= 0], %w[mime-types >= 0], %w[mail >= 2.2.5]], triples
    assert triples.map(&:first).tally.values.all?(1)
  end
end
