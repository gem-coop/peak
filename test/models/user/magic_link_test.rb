require "test_helper"

class User::MagicLinkTest < ActiveSupport::TestCase
  test "signed_id roundtrip" do
    magic_link = users.plain.magic_link
    found = User::MagicLink.find_signed!(magic_link.signed_id)
    assert_equal users.plain, found.user
  end

  test "signed_id expires" do
    signed_id = users.plain.magic_link.signed_id
    travel 15.minutes + 1.second

    assert_raises(ActiveSupport::MessageVerifier::InvalidSignature) do
      User::MagicLink.find_signed!(signed_id)
    end
  end

  test "mailer" do
    mail = users.plain.magic_link.mailer
    assert_equal [users.plain.email_address], mail.to
    assert_match "Sign in", mail.subject
  end
end
