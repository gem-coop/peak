require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "system?" do
    refute users.owner.system?
    refute users.plain.system?
    assert users.system.system?
  end

  test "normalizes email_address" do
    user = User.new(email_address: "  Mixed.Case@Example.com  ")
    assert_equal "mixed.case@example.com", user.email_address
  end

  test "email_address uniqueness is case-insensitive" do
    duplicate = User.new(name: "Duplicate", email_address: users.plain.email_address.upcase)
    refute duplicate.valid?
    assert duplicate.errors[:email_address].any?
  end

  test "finds existing user regardless of email_address casing" do
    assert_equal users.plain, User.find_by(email_address: users.plain.email_address.upcase)
  end

  test "rejects a blocked email_address domain" do
    user = User.new(name: "Disposable", email_address: "someone@#{blocked_domains.mail_com.name}")

    refute user.valid?
    assert_equal ["uses a blocked domain"], user.errors[:email_address]
  end

  test "leaves existing users alone when their domain gets blocked" do
    blocked_domains.create name: "example.com"

    users.unverified_plain.email_verification.verify
    assert users.unverified_plain.reload.verified?
  end
end
