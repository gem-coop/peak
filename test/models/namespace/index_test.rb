require "test_helper"

class Namespace::IndexTest < ActiveSupport::TestCase
  test "defers loading versions_contents then only fires one query" do
    index = namespaces.gemcoop.external_index
    assert_nil index.versions_contents_before_type_cast

    assert_queries_match /versions_contents/ do
      assert_match "oaken", index.versions_contents
    end

    assert_no_queries { index.versions_contents }
  end

  test "compaction" do
    index = namespaces.public.external_index
    assert_changes(-> { index.last_compacted_at }) { index.compact }

    assert_match gems.actionview.info.envelope, index.versions_contents
  end
end
