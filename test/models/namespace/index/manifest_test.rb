require "test_helper"

class Namespace::Index::ManifestTest < ActiveSupport::TestCase
  # The bulk computed_contents must match the old per-gem `latest_for(name).envelope` output exactly.
  test "computed_contents matches per-gem envelopes" do
    index = namespaces.public.default_index

    expected = index.gems.reorder(:id).filter_map { index.versions.latest_for(_1.name)&.envelope }.join

    assert_predicate expected, :present?
    assert_equal expected, index.manifest.send(:computed_contents)
  end
end
