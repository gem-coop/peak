require "test_helper"

class Namespace::Gem::Version::MetadataTest < ActiveSupport::TestCase
  test "basic parsing" do
    metadatas = gems.oaken.versions.map(&:metadata)
    assert metadatas.all?(&:checksum?)
    assert_empty metadata.filter_map(&:rubygems)

    rubies = metadatas.pluck :ruby
    assert_includes rubies, ">= 3.2"
    assert_includes rubies, ">= 3.0.0"
  end
end
