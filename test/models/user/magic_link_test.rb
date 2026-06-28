require "test_helper"

class User::MagicLinkTest < ActiveSupport::TestCase
  test "token roundtrip" do
    token = users.plain.magic_link.token
    assert_equal users.plain, User::MagicLink.find_by_token!(token).user
  end

  test "token expires" do
    token = users.plain.magic_link.token
    travel 15.minutes + 1.second

    assert_nil User::MagicLink.find_by_token(token)
  end

  test "mailer" do
    mail = users.plain.magic_link.mailer
    assert_equal [users.plain.email_address], mail.to
    assert_match "Sign in", mail.subject
  end
end
