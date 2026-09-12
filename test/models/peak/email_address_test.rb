require "test_helper"

class Peak::EmailAddressTest < ActiveSupport::TestCase
  test "extracts the domain, downcased" do
    assert_equal "mailinator.com", Peak::EmailAddress.new("someone@MAILINATOR.com").domain
    assert_equal "b.com", Peak::EmailAddress.new("Someone <a@B.com>").domain
  end

  test "blocks regardless of casing and subdomain" do
    %W[garbage@0-mail.com garbage@0-MAIL.COM garbage@0-Mail.Com garbage@relay.0-mail.com
       <garbage@0-mail.com>].each do |address|
      assert Peak::EmailAddress.new(address).blocked_domain?, "expected #{address} to be blocked"
    end

    refute Peak::EmailAddress.new("someone@example.com").blocked_domain?
  end

  test "survives addresses Mail can't parse" do
    ["someone@", "a b@c.com", "@nowhere.com", "a@b@c.com", "garbage", "", nil].each do |address|
      email_address = Peak::EmailAddress.new(address)

      assert_nothing_raised { email_address.blocked_domain? }
      refute email_address.blocked_domain?, "expected #{address.inspect} to pass"
    end
  end

  test "keeps the address it was given" do
    assert_equal "someone@example.com", Peak::EmailAddress.new("someone@example.com").to_s
    assert_equal "garbage", Peak::EmailAddress.new("garbage").to_s
  end
end
