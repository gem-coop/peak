require "test_helper"

class Namespace::IndexTest < ActiveSupport::TestCase
  test "can't destroy default index" do
    index = namespaces.gemcoop.default_index.tap(&:destroy)
    refute index.destroyed?
  end
end
