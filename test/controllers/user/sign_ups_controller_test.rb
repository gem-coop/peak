require "test_helper"

class User::SignUpsControllerTest < ActionDispatch::IntegrationTest
  test "get new" do
    get user_sign_ups_url
    assert_response :success
  end

  test "post create success" do
    assert_increments User, Namespace, Namespace::Access do
      post user_sign_ups_url, params: sign_up_params
    end
    assert_response :success

    Namespace::Access.last.tap do |access|
      assert access.owner?
      assert_equal "Someone", access.user.name
      assert_equal "someone@example.com", access.user.email_address
      assert_equal "@someone", access.namespace.name
    end

    perform_enqueued_jobs
    assert_emails 1
    assert mail = ActionMailer::Base.deliveries.last
    assert_equal ["someone@example.com"], mail.to
    assert_match "user/email_verifications/", mail.text_part.body.to_s

    namespace = Namespace.last
    assert_emails(1) { namespace.approve }
    assert_no_emails { namespace.approve }
  end

  test "post create with taken email address" do
    refute_increments User, Namespace, Namespace::Access do
      post user_sign_ups_url, params: sign_up_params(email_address: users.owner.email_address)
    end
    assert_response :unprocessable_entity
  end

  test "post create with taken namespace name" do
    refute_increments User, Namespace, Namespace::Access do
      post user_sign_ups_url, params: sign_up_params(namespace_name: namespaces.gemcoop.name)
    end
    assert_response :unprocessable_entity
  end

  private
    def sign_up_params(name: "Someone", email_address: "someone@example.com", namespace_name: "@someone")
      { user_sign_up: { name:, email_address:, namespace_name: } }
    end
end
