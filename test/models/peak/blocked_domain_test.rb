require "test_helper"

class Peak::BlockedDomainTest < ActiveSupport::TestCase
  test "normalizes name" do
    assert_equal "mailinator.com", Peak::BlockedDomain.new(name: "  MailInator.Com ").name
  end

  test "requires a registrable domain" do
    %w[com co.uk mailinator not_a_domain.com -nope.com].each do |name|
      refute Peak::BlockedDomain.new(name:).valid?, "expected #{name} to be rejected"
    end

    assert Peak::BlockedDomain.new(name: "mailinator.com").valid?
    assert Peak::BlockedDomain.new(name: "relay.mailinator.com").valid?
  end

  test "refuses to block a major email provider" do
    provider = Peak::BlockedDomain.new(name: "gmail.com")

    refute provider.valid?
    assert_equal ["is a major email provider and can't be blocked"], provider.errors[:name]
  end

  test "include? covers the domain and its subdomains" do
    assert Peak::BlockedDomain.include?("0-mail.com")
    assert Peak::BlockedDomain.include?("relay.0-mail.com")
    refute Peak::BlockedDomain.include?("not0-mail.com")
    refute Peak::BlockedDomain.include?("example.com")
  end

  test "include? ignores blank and malformed domains" do
    [nil, "", "   ", "com", "nope"].each do |domain|
      refute Peak::BlockedDomain.include?(domain), "expected #{domain.inspect} to pass"
    end
  end
end
