require "test_helper"

class Peak::Gem::LinkTest < ActiveSupport::TestCase
  test "accepts absolute http(s) URLs with a host" do
    ["http://example.com", "https://example.com/path", "HTTPS://Example.com"].each do |value|
      assert Peak::Gem::Link.safe?(value), "expected #{value.inspect} to be safe"
    end
  end

  test "rejects unsafe schemes, hostless and malformed URLs" do
    ["javascript:alert(1)", "data:text/html,evil", "//evil.com", "http:///nohost",
     "ftp://example.com", "not a url", "", nil].each do |value|
      refute Peak::Gem::Link.safe?(value), "expected #{value.inspect} to be unsafe"
    end
  end
end
