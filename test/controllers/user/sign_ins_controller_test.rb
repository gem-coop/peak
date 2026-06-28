require "test_helper"

class User::SignInsControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "get new" do
    get new_sign_in_url
    assert_response :success
  end

  test "post create" do
    post sign_in_index_url, params: { email_address: users.plain.email_address }
    assert_response :success

    perform_enqueued_jobs
    assert_emails 1
    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal [users.plain.email_address], mail.to
      assert_match "Sign in", mail.subject
      assert_match "sign_in/", mail.text_part.body.to_s
    end
  end

  test "create doesn't let slip if the user doesn't exist" do
    post sign_in_index_url, params: { email_address: "nonexistent@example.com" }
    assert_response :success
    assert_match "Check your email", response.body

    perform_enqueued_jobs
    assert_emails 0
  end

  test "create rate limit" do
    4.times do
      post sign_in_index_url, params: { email_address: users.plain.email_address }
    end

    assert_response :too_many_requests
  end

  test "show creates session from magic link" do
    assert_increments User::Session do
      get sign_in_url(users.plain.magic_link.signed_id)
    end
    assert_redirected_to root_url
    assert_equal "no-referrer", response.headers["referrer-policy"]
  end

  test "show creates session from magic link — with redirect_url" do
    get new_sign_in_url(redirect_url: dashboard_url)

    assert_increments User::Session do
      get sign_in_url(users.plain.magic_link.signed_id)
    end
    assert_redirected_to dashboard_url
  end

  test "show with expired magic link" do
    signed_id = users.plain.magic_link.signed_id
    travel 15.minutes + 1.second

    get sign_in_url(signed_id)
    assert_redirected_to new_sign_in_url
  end
end
