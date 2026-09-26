require "test_helper"

class NamespaceLifecycleTest < ActionDispatch::IntegrationTest
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "a new user signs up, confirms their email, and signs in" do
    assert_increments User, Namespace::Submission do
      request_namespace name: "Ada", email_address: "ada@example.com", namespace_name: "@ada"
    end
    assert_response :success

    user = User.find_by!(email_address: "ada@example.com")
    refute user.verified?, "a brand-new user starts unverified"

    get user_email_verification_url(user.email_verification.token)
    assert_response :success
    assert user.reload.verified?, "email is confirmed after visiting the link"

    get sign_in_url(user.magic_link.token)
    assert_redirected_to dashboard_url
    follow_redirect!
    assert_response :success
  end

  test "approval creates the namespace and emails the owner a link to it" do
    request_namespace name: "Ben", email_address: "ben@example.com", namespace_name: "@ben"

    submission = Namespace::Submission.find_by!(name: "@ben")
    assert submission.pending?
    assert_nil Namespace.find_by(name: "@ben"), "no namespace exists while pending"

    # What Avo::Actions::Approve does.
    assert_increments Namespace do
      perform_enqueued_jobs do
        submission.resolve! :approved
        submission.process_approved
      end
    end
    assert submission.reload.approved?
    assert_includes Namespace.named("@ben").owners, submission.owner

    approved = ActionMailer::Base.deliveries.find { it.subject == "@ben approved!" }
    assert approved, "owner receives an approval email"
    assert_equal ["ben@example.com"], approved.to

    get url_in(approved, %r{https?://[^\s"'<>]*#{Regexp.escape(submission.name)}})
    assert_response :success, "the link in the email lands on the live namespace profile"
  end

  test "a rejected request never creates a namespace" do
    request_namespace name: "Cara", email_address: "cara@example.com", namespace_name: "@cara"
    submission = Namespace::Submission.find_by!(name: "@cara")

    refute_increments Namespace do
      submission.resolve! :rejected
    end

    assert submission.reload.rejected?
    assert_nil Namespace.find_by(name: "@cara")
  end

  test "an owner pushes a gem to their newly approved namespace" do
    request_namespace name: "Dee", email_address: "dee@example.com", namespace_name: "@dee"
    user = User.find_by!(email_address: "dee@example.com")
    submission = Namespace::Submission.find_by!(name: "@dee")

    submission.resolve! :approved
    submission.process_approved
    get user_email_verification_url(user.email_verification.token)
    assert user.reload.verified?

    post user_push_keys_url, params: { email_address: "dee@example.com" }
    token = user.push_key.token
    package = file_fixture "peak/peak-0.2.0.gem"

    assert_increments Namespace::Gem::Version do
      post namespace_gem_push_url(namespace: "@dee"),
        env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{token}" }
    end
    assert_response :success
    assert_match "peak-0.2.0.gem uploaded", response.body
  end

  test "sign-up and sign-in driven entirely by the emailed links" do
    perform_enqueued_jobs do
      request_namespace name: "Eve", email_address: "eve@example.com", namespace_name: "@eve"
    end

    welcome = last_email
    assert_equal ["eve@example.com"], welcome.to
    assert_equal "Welcome to gem.coop", welcome.subject

    get url_in(welcome, %r{https?://\S+/user/email_verifications/[^\s"'<>]+})
    assert_response :success
    assert User.find_by!(email_address: "eve@example.com").verified?

    perform_enqueued_jobs do
      post sign_in_index_url, params: { email_address: "eve@example.com" }
    end

    magic = last_email
    assert_equal ["eve@example.com"], magic.to
    assert_equal "Sign in to gem.coop", magic.subject

    get url_in(magic, %r{https?://\S+/sign_in/[^\s"'<>]+})
    assert_redirected_to dashboard_url
  end

  private
    def request_namespace(name:, email_address:, namespace_name:)
      post user_sign_ups_url, params: { user_sign_up: { name:, email_address:, namespace_name: } }
    end

    def last_email = ActionMailer::Base.deliveries.last

    def url_in(mail, pattern)
      body = (mail.text_part&.body || mail.body).to_s
      body[pattern] or flunk "no link matching #{pattern.inspect} in email to #{mail&.to.inspect}"
    end
end
