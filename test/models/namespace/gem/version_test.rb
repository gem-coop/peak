require "test_helper"

class Namespace::Gem::VersionTest < ActiveSupport::TestCase
  test "versions" do
    refs = gems.oaken.versions.pluck :ref
    assert_includes refs, "0.9.1"
    assert_includes refs, "1.0.0"
  end

  test "checksum parsing" do
    version = versions.by gems.actionview, ref: "8.1.0"
    assert_equal "b7e8770a5aacd389a3c04916d29609a53459447fcbf747150437136d44c1d1f3", version.checksum
  end

  test "PURL format" do
    version = versions.by(gems.actionview, ref: "8.1.0")
    assert_equal "pkg:gem/gem.coop/rubygems/actionview@8.1.0", version.to_purl

    version.update! platform: Peak::Platform.linux.aarch64.first
    assert_equal "pkg:gem/gem.coop/rubygems/actionview@8.1.0?platform=aarch64-linux", version.to_purl
  end
end
