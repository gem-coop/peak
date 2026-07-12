require "test_helper"

class Namespace::IndexTest < ActiveSupport::TestCase
  test "can't destroy stable index" do
    index = namespaces.gemcoop.stable_index.tap(&:destroy)
    refute index.destroyed?
  end
end
