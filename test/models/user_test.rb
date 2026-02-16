require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "system?" do
    refute users.owner.system?
    refute users.plain.system?
    assert users.system.system?
  end
end
