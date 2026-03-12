require "test_helper"

class User::SignInsControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "get new" do
    get sign_in_url
    assert_response :success
  end

  test "post create" do
    post sign_in_url, params: { email_address: users.plain.email_address }
    assert_response :success

    perform_enqueued_jobs
    assert_emails 1
    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal [users.plain.email_address], mail.to
      assert_match "Sign in", mail.subject
      assert_match "user/sessions/", mail.text_part.body.to_s
    end
  end

  test "create doesn't let slip if the user doesn't exist" do
    post sign_in_url, params: { email_address: "nonexistent@example.com" }
    assert_response :success
    assert_match "Check your email", response.body

    perform_enqueued_jobs
    assert_emails 0
  end

  test "create rate limit" do
    4.times do
      post sign_in_url, params: { email_address: users.plain.email_address }
    end

    assert_response :too_many_requests
  end
end
