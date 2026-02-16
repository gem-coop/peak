require "test_helper"

class User::PushKeysControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "get new" do
    get new_user_push_key_url
    assert_response :success
  end

  test "post create" do
    post user_push_keys_url, params: { email_address: users.plain.email_address }
    assert_response :success

    perform_enqueued_jobs
    assert_emails 1
    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal [Peak.system_user.email_address], mail.from
      assert_equal [users.plain.email_address], mail.to
      assert_match "Push Key", mail.subject
      assert_match "GEM_HOST_API_KEY", mail.text_part.body.to_s
      assert_match "/@gemcoop", mail.text_part.body.to_s
    end
  end

  test "create doesn't let slip if the user doesn't exist" do
    post user_push_keys_url, params: { email_address: "nonexistent@example.com" }
    assert_response :success
    assert_match "Email sent!", response.body
  end

  test "create deletes existing push key" do
    key = users.plain.create_push_key

    post user_push_keys_url, params: { email_address: users.plain.email_address }

    assert_raises(ActiveRecord::RecordNotFound) { key.reload }
  end

  test "create rate_limit" do
    2.times do
      post user_push_keys_url, params: { email_address: users.plain.email_address }
    end

    assert_response :too_many_requests
  end
end
