require "test_helper"

class User::EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "get new" do
    get new_user_email_verification_url
    assert_response :success
  end

  test "post create" do
    assert_emails 1 do
      post user_email_verifications_url, params: { email_address: users.unverified_plain.email_address }
    end
    assert_response :success
  end

  test "post create -- already verified" do
    assert_no_emails do
      post user_email_verifications_url, params: { email_address: users.plain.email_address }
    end
    assert_response :unprocessable_entity
  end

  test "get show" do
    token = users.unverified_plain.email_verification.token

    assert_changes -> { users.unverified_plain.email_address_verified_at }, from: nil do
      get user_email_verification_url(token)
    end
    assert_response :success
    assert_equal "no-referrer", response.headers["referrer-policy"]

    get user_email_verification_url(token)
    assert_redirected_to new_user_email_verification_url
  end

  test "get show expired" do
    token = users.plain.email_verification.token
    travel 24.hours + 1.second

    get user_email_verification_url(token)
    assert_redirected_to new_user_email_verification_url
  end
end
