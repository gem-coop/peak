require "test_helper"

class Search::IndexTest < ActiveSupport::TestCase
  test "indexing" do
    namespace = namespaces.gemcoop
    version = namespace.default_index.versions.latest_for(:oaken)

    assert_equal "@gemcoop", namespace.search_index.content
    assert_equal "@gemcoop oaken #{version.summary}", version.gem.search_index.content
  end

  test "reindexing" do
    version = namespaces.gemcoop.default_index.versions.latest_for(:oaken)
    version.update! summary: "new summary" # Simulate a gem push that changes latest summary
    version.gem.reindex

    assert_equal "@gemcoop oaken new summary", version.gem.search_index.content
  end
end
