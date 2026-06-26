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

  test "ref must be a valid RubyGems version" do
    ["1.0\n9", "1.0 0", "v1", "", "1.0.0; rm -rf"].each do |bad|
      version = gems.oaken.versions.build(ref: bad).tap(&:valid?)
      assert version.errors.include?(:ref), "expected a ref error for #{bad.inspect}"
    end

    %w[1.0.0 0.9.1 1.0.0-arm-linux 8.1.0.pre.1].each do |good|
      version = gems.oaken.versions.build(ref: good).tap(&:valid?)
      assert version.errors.exclude?(:ref), "expected ref #{good.inspect} to pass version format"
    end
  end
end
