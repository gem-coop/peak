require "test_helper"

class Namespace::Gem::SearchIndexTest < ActiveSupport::TestCase
  def version = namespaces.gemcoop.stable_index.versions.latest_for(:oaken)

  test "indexing" do
    assert_equal "oaken #{version.summary}", version.gem.search_index.content
  end

  test "reindexing" do
    version.update! summary: "new summary" # Simulate a gem push that changes latest summary
    version.gem.reindex

    assert_equal "oaken new summary", version.gem.search_index.content
  end
end
