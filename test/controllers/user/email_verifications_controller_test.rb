require "test_helper"

class User::EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "get show" do
    assert_changes -> { users.plain.email_address_verified_at }, from: nil do
      get user_email_verification_url(users.plain.email_verification.signed_id)
    end
    assert_response :success
  end

  test "get show expired" do
    id = users.plain.email_verification.signed_id
    travel 24.hours + 1.second

    assert_raise ActiveSupport::MessageVerifier::InvalidSignature do
      get user_email_verification_url(id)
    end
  end
end
