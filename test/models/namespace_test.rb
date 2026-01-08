require "test_helper"

class NamespaceTest < ActiveSupport::TestCase
  test "name" do
    assert_equal "Gem Coop", namespaces.gemcoop.name
  end
end
