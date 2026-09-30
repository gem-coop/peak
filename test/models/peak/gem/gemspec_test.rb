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
end
