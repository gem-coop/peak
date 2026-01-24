require "test_helper"

class Namespace::Gem::VersionTest < ActiveSupport::TestCase
  test "versions" do
    refs = gems.oaken.versions.pluck :ref
    assert_includes refs, "0.9.1"
    assert_includes refs, "1.0.0"
  end

  test "basic parsing" do
    metadatas = gems.oaken.versions
    assert metadatas.all?(&:checksum?)
    assert_empty metadata.filter_map(&:rubygems)

    rubies = metadatas.pluck :ruby
    assert_includes rubies, ">= 3.2"
    assert_includes rubies, ">= 3.0.0"
  end

  test "checksum parsing" do
    version = versions.by gems.actionview, ref: "8.1.0"
    assert_equal "b7e8770a5aacd389a3c04916d29609a53459447fcbf747150437136d44c1d1f3", version.checksum
  end
end
