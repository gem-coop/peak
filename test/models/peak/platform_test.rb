require "test_helper"

class Peak::PlatformTest < ActiveSupport::TestCase
  test "parsing" do
    assert_platform "",          "ruby",   ""
    assert_platform "universal", "darwin", ""
    assert_platform "universal", "darwin", "22"
    assert_platform "arm64",     "darwin", ""
    assert_platform "arm",       "linux",  ""
    assert_platform "arm",       "linux",  "gnueabihf"
    assert_platform "arm64",     "linux",  ""
    assert_platform "aarch64",   "linux",  ""
    assert_platform "aarch64",   "linux",  "musl"
  end

  private
    def assert_platform(arch, name, specifier, **)
      assert Peak::Platform.exists?(arch:, name:, specifier:, **)
    end
end
