require "test_helper"

class User::SignUpsControllerTest < ActionDispatch::IntegrationTest
  setup { User::SignUpsController.cache_store.clear }

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
    refute_increments User, Namespace do
      assert_increments users.owner.submissions do
        post user_sign_ups_url, params: sign_up_params(email_address: users.owner.email_address)
      end
    end
    assert_response :success

    Namespace::Submission.last.tap do |submission|
      assert_equal "@someone", submission.name
      assert_equal "Owner", submission.owner.name # We don't override the name.
      assert_equal users.owner.email_address, submission.owner.email_address
    end
  end

  test "post create with resolved namespace name" do
    submissions.rejected.create name: "@rejected"

    refute_increments User, Namespace::Submission do
      post user_sign_ups_url, params: sign_up_params(namespace_name: "@rejected")
    end
    assert_response :unprocessable_entity
  end

  test "post create with pending namespace name" do
    submissions.pending.create name: "@pending"

    assert_increments User, Namespace::Submission do
      post user_sign_ups_url, params: sign_up_params(namespace_name: "@pending")
    end

    assert_response :success
  end

  test "post create rate_limit" do
    limit = User::SignUpsController.rate_limiting(by: "someone@example.com")
    limit.increment by: 4

    post user_sign_ups_url, params: sign_up_params(namespace_name: "@gemcoop")
    assert_equal 4, limit.read # Form submission errors don't count against rate_limit

    limit.increment by: 1

    post user_sign_ups_url, params: sign_up_params(namespace_name: "@one-for-the-road")
    assert_response :too_many_requests
  end

  private
    def sign_up_params(name: "Someone", email_address: "someone@example.com", namespace_name: "@someone")
      { user_sign_up: { name:, email_address:, namespace_name: } }
    end
end
