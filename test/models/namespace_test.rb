require "test_helper"

class NamespaceTest < ActiveSupport::TestCase
  test "name" do
    assert_equal "@gemcoop", namespaces.gemcoop.name
  end
end
