require "test_helper"

class User::SignUpsControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "get new" do
    get user_sign_ups_url
    assert_response :success
  end

  test "post create success" do
    assert_increments User, Namespace::Submission do
      post user_sign_ups_url, params: sign_up_params
    end
    assert_response :success

    Namespace::Submission.last.tap do |submission|
      assert_equal "@someone", submission.name
      assert_equal "Someone", submission.owner.name
      assert_equal "someone@example.com", submission.owner.email_address
    end

    perform_enqueued_jobs
    assert_emails 1
    assert mail = ActionMailer::Base.deliveries.last
    assert_equal ["someone@example.com"], mail.to
    assert_match "user/email_verifications/", mail.text_part.body.to_s
  end

  test "post create with taken email address" do
    refute_increments User, Namespace, Namespace::Access do
      post user_sign_ups_url, params: sign_up_params(email_address: users.owner.email_address)
    end
    assert_response :unprocessable_entity
  end

  test "post create with resolved namespace name" do
    submissions.rejected.create name: "@rejected"

    refute_increments User, Namespace::Submission do
      post user_sign_ups_url, params: sign_up_params(namespace_name: "@rejected")
    end
    assert_response :unprocessable_entity
  end

  test "post create rate_limit" do
    2.times do
      post user_sign_ups_url, params: sign_up_params
    end

    assert_response :too_many_requests
  end

  test "post create with pending namespace name" do
    submissions.pending.create name: "@pending"

    assert_increments User, Namespace::Submission do
      post user_sign_ups_url, params: sign_up_params(namespace_name: "@pending")
    end
    assert_response :success
  end

  private
    def sign_up_params(name: "Someone", email_address: "someone@example.com", namespace_name: "@someone")
      { user_sign_up: { name:, email_address:, namespace_name: } }
    end
end
