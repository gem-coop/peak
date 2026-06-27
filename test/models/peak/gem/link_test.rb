require "test_helper"

class Peak::Gem::LinkTest < ActiveSupport::TestCase
  test "accepts absolute http(s) URLs with a host" do
    assert_parsed "http://example.com"
    assert_parsed "https://example.com/path"
    assert_parsed "https://github.com/gem-coop/peak/blob/main/CHANGELOG.md"
    assert_parsed "HTTPS://Example.com", to: "https://Example.com"
  end

  test "rejects unsafe schemes, hostless and malformed URLs" do
    assert_nil Peak::Gem::Link.parse("javascript:alert(1)")
    assert_nil Peak::Gem::Link.parse("data:text/html,evil")
    assert_nil Peak::Gem::Link.parse("//evil.com")
    assert_nil Peak::Gem::Link.parse("http:///nohost")
    assert_nil Peak::Gem::Link.parse("ftp://example.com")
    assert_nil Peak::Gem::Link.parse("not a url")
    assert_nil Peak::Gem::Link.parse("")
    assert_nil Peak::Gem::Link.parse(nil)
  end

  private
    def assert_parsed(value, to: value)
      assert_equal to, Peak::Gem::Link.parse(value)
    end
end
