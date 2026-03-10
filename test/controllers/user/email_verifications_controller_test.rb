require "test_helper"

class User::EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "get new" do
    get new_user_email_verification_url
    assert_response :success
  end

  test "post create" do
    assert_emails 1 do
      post user_email_verifications_url, params: { email_address: users.plain.email_address }
    end
    assert_response :success
  end

  test "post create -- already verified" do
    users.plain.email_verification.verify

    assert_no_emails do
      post user_email_verifications_url, params: { email_address: users.plain.email_address }
    end
    assert_response :unprocessable_entity
  end

  test "get show" do
    assert_changes -> { users.plain.email_address_verified_at }, from: nil do
      get user_email_verification_url(users.plain.email_verification.signed_id)
    end
    assert_response :success
  end

  test "get show expired" do
    id = users.plain.email_verification.signed_id
    travel 24.hours + 1.second

    get user_email_verification_url(id)
    assert_redirected_to new_user_email_verification_url
  end
end
