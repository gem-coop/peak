require "test_helper"

class Peak::GemTest < ActiveSupport::TestCase
  test "name valid" do
    assert Peak::Gem.name?("oaken")
    assert Peak::Gem.name?("active_job-performs")
    assert Peak::Gem.name?("rails-html-sanitizer")
    assert Peak::Gem.name?("a.b")
    assert Peak::Gem.name?("Foo_Bar.9")
    assert Peak::Gem.name?("1.2.3")
    assert Peak::Gem.name?("9foo")
  end

  test "name invalid" do
    refute Peak::Gem.name?("a")
    refute Peak::Gem.name?("9")

    refute Peak::Gem.name?("safe\nforged 9.9.9 deadbeef")
    refute Peak::Gem.name?("safe\rforged")
    refute Peak::Gem.name?("safe\x00x")
    refute Peak::Gem.name?("has space")
    refute Peak::Gem.name?("name@evil")
    refute Peak::Gem.name?("a/b")
    refute Peak::Gem.name?("a:b")

    refute Peak::Gem.name?("_leading")
    refute Peak::Gem.name?("-leading")
    refute Peak::Gem.name?(".leading")
  end

  test "version splitting with extra dash" do
    assert_equal ["active_job-performs", "1.0.0"], Peak::Gem.version("active_job-performs-1.0.0.gem")
    assert_equal ["active_job-performs", "1.0.0-arm64-darwin-23"], Peak::Gem.version("active_job-performs-1.0.0-arm64-darwin-23.gem")
  end
end
