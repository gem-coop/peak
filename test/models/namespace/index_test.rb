require "test_helper"

class Namespace::IndexTest < ActiveSupport::TestCase
  test "can't destroy default index" do
    index = namespaces.gemcoop.default_index.tap(&:destroy)
    refute index.destroyed?
  end

  test "compaction" do
    manifest = namespaces.public.default_index.manifest
    assert_changes(-> { manifest.compacted_at }) { manifest.compact }

    assert_match gems.actionview.versions.last.envelope, manifest.contents
  end
end
