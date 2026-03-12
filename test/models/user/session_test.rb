require "test_helper"

class User::SessionTest < ActiveSupport::TestCase
  test "belongs to user" do
    session = users.plain.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")
    assert_equal users.plain, session.user
  end

  test "destroying user destroys sessions" do
    user = User.create!(name: "Temp", email_address: "temp@example.com")
    user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")

    assert_difference -> { User::Session.count }, -1 do
      user.destroy
    end
  end
end
