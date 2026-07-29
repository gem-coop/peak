require "test_helper"

class Namespace::IndexTest < ActiveSupport::TestCase
  test "can't destroy stable index" do
    index = namespaces.gemcoop.stable_index.tap(&:destroy)
    refute index.destroyed?
  end

  test "version from a new gem" do
    index = namespaces.gemcoop.stable_index

    assert_increments Namespace::Gem do
      version = index.version_from(name: "new-gem", ref: "1.0.0")

      refute version.persisted?
      assert_equal index, version.index
      assert_equal index.namespace.gems.find_by!(name: "new-gem"), version.gem
    end
  end
end
