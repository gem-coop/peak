require "test_helper"
require_relative "../support/gem_server_client"
require_relative "../support/namespace_provisioning"

class NamespaceLifecycleTest < ActionDispatch::IntegrationTest
  include GemServerClient, NamespaceProvisioning
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "a requested namespace goes live once approved and the owner is emailed a link" do
    register "ben@example.com", requesting: "@ben"

    submission = Namespace::Submission.find_by!(name: "@ben")
    assert submission.pending?
    assert_nil Namespace.find_by(name: "@ben"), "no namespace exists while pending"

    namespace = assert_increments(Namespace) { approve "@ben" }
    assert submission.reload.approved?
    assert_includes namespace.owners, submission.owner

    approved = ActionMailer::Base.deliveries.find { it.subject == "@ben approved!" }
    assert approved, "owner receives an approval email"
    assert_equal ["ben@example.com"], approved.to
    assert url_in(approved, %r{https?://[^\s"'<>]*#{Regexp.escape(submission.name)}}), "the email links to the namespace"

    assert_equal %w[stable], namespace.indexes.pluck(:slug)
    assert_empty compact_index_versions(namespace), "the live namespace serves an empty index"
  end

  test "a new user signs up, verifies and signs in through the emailed links, then signs out" do
    assert_increments User, Namespace::Submission do
      perform_enqueued_jobs { register "eve@example.com", requesting: "@eve" }
    end
    refute User.find_by!(email_address: "eve@example.com").verified?, "a brand-new user starts unverified"

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

    get dashboard_url
    assert_response :success, "the signed-in user reaches the dashboard"

    delete sign_out_url

    get dashboard_url
    assert_redirected_to new_sign_in_url(redirect_url: dashboard_url), "the dashboard is gated again once signed out"
  end

  private
    def last_email = ActionMailer::Base.deliveries.last

    def url_in(mail, pattern)
      body = (mail.text_part&.body || mail.body).to_s
      body[pattern] or flunk "no link matching #{pattern.inspect} in email to #{mail&.to.inspect}"
    end
end
