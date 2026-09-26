require "test_helper"

class AccountFlowsTest < ActionDispatch::IntegrationTest
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "registering with valid details succeeds" do
    assert_increments User, Namespace::Submission do
      post user_sign_ups_url, params: sign_up_params
    end
    assert_response :success
  end

  test "registering for an already-taken namespace is denied" do
    refute_increments User, Namespace::Submission do
      post user_sign_ups_url, params: sign_up_params(namespace_name: "@gemcoop")
    end
    assert_response :unprocessable_entity
  end

  test "verifying an email with a valid link succeeds" do
    user = users.unverified_plain

    assert_changes -> { user.reload.verified? }, from: false, to: true do
      get user_email_verification_url(user.email_verification.token)
    end
    assert_response :success
  end

  test "verifying an email with an invalid link is denied" do
    get user_email_verification_url("not-a-real-token")
    assert_redirected_to new_user_email_verification_url
  end

  test "signing in with a valid magic link succeeds" do
    assert_increments User::Session do
      get sign_in_url(users.plain.magic_link.token)
    end
    assert_redirected_to dashboard_url
  end

  test "signing in with an invalid magic link is denied" do
    refute_increments User::Session do
      get sign_in_url("not-a-real-token")
    end
    assert_redirected_to new_sign_in_url
  end

  test "signing out ends the session" do
    get sign_in_url(users.plain.magic_link.token)
    get dashboard_url
    assert_response :success, "the signed-in user reaches the dashboard"

    delete sign_out_url

    get dashboard_url
    assert_redirected_to new_sign_in_url(redirect_url: dashboard_url), "the dashboard is gated again once signed out"
  end

  private
    def sign_up_params(name: "Newbie", email_address: "newbie@example.com", namespace_name: "@newbie")
      { user_sign_up: { name:, email_address:, namespace_name: } }
    end
end
