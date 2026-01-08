require "test_helper"

class Namespace::AccessTest < ActiveSupport::TestCase
  test "owner" do
    accesses = namespaces.gemcoop.accesses

    assert_equal [users.kasper], accesses.owner.extract_associated(:user)
    assert_equal [users.plain], accesses.plain.extract_associated(:user)
  end
end
