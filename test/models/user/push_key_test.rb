require "test_helper"

class User::PushKeyTest < ActiveSupport::TestCase
  setup { @key = users.plain.push_key }

  test "expires_at default" do
    freeze_time
    assert_equal 24.hours.from_now, users.plain.build_push_key.expires_at
  end

  test "expiry scopes" do
    assert_includes User::PushKey.active, @key
    refute_includes User::PushKey.expired, @key

    travel @key.expires_at.to_i + 1.second
    refute_includes User::PushKey.active, @key
    assert_includes User::PushKey.expired, @key
  end

  test "expiry predicates" do
    assert @key.active?
    refute @key.expired?

    travel @key.expires_at.to_i + 1.second
    refute @key.active?
    assert @key.expired?
  end
end
