require "test_helper"
require_relative "../support/gem_server_client"

class BundlerResolutionTest < ActionDispatch::IntegrationTest
  include GemServerClient
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "resolves and downloads a gem from an existing namespace" do
    namespace = namespaces.gemcoop

    versions = compact_index_versions(namespace)
    assert_equal ["0.1.0"], versions["peak"]
    assert_equal ["0.9.1", "1.0.0"], versions["oaken"]

    assert_includes compact_index_info(namespace, gems.peak), "0.1.0"

    assert_equal "peak", fetch_gem(namespace, gems.peak.versions.first).name
  end

  test "info exposes a gem's dependency requirements for resolution" do
    get namespace_info_url(namespace: namespaces.gemcoop, id: gems.peak)
    assert_response :success
    assert_match "oaken:>= 0.9&~> 1.0.0", response.body
  end

  test "a freshly pushed gem becomes resolvable and downloadable" do
    token = provision_push_token namespace_name: "@pat", email_address: "pat@example.com"

    refute_includes compact_index_versions("@pat").keys, "peak", "nothing is published yet"

    perform_enqueued_jobs do
      gem_push "@pat", file_fixture("peak/peak-0.2.0.gem").binread, token: token
    end
    assert_response :success

    assert_equal ["0.2.0"], compact_index_versions("@pat")["peak"]
    assert_includes compact_index_info("@pat", "peak"), "0.2.0"

    version = Namespace.named("@pat").stable_index.gems.find_by!(name: "peak").versions.sole
    assert_equal "peak", fetch_gem("@pat", version).name
  end

  test "a private index is not resolvable through the public compact index" do
    namespace = namespaces.gemcoop

    assert_includes compact_index_versions(namespace).keys, "peak"

    get namespace_versions_url(namespace:, index: "private")
    assert_response :not_found
  end

  test "a gem in one namespace is not visible from another" do
    assert_includes compact_index_versions(namespaces.gemcoop).keys, "peak"
    refute_includes compact_index_versions(namespaces.blank).keys, "peak", "namespaces are isolated"
  end

  test "pushing to a namespace you do not own is rejected" do
    outsider = provision_push_token namespace_name: "@outsider", email_address: "outsider@example.com"

    refute_increments Namespace::Gem::Version do
      gem_push namespaces.gemcoop, file_fixture("peak/peak-0.2.0.gem").binread, token: outsider
    end
    assert_response :unauthorized
    assert_match "doesn't have access", response.body
  end

  test "a downloaded gem is byte-for-byte what was pushed" do
    token = provision_push_token namespace_name: "@bits", email_address: "bits@example.com"
    package = file_fixture("peak/peak-0.2.0.gem").binread

    perform_enqueued_jobs { gem_push "@bits", package, token: token }

    version = Namespace.named("@bits").stable_index.gems.find_by!(name: "peak").versions.sole
    get namespace_gems_url(namespace: "@bits", id: version)
    assert_response :success
    assert_equal package, response.body, "the served gem matches the uploaded bytes exactly"
  end

  test "every pushed version is listed for resolution" do
    token = provision_push_token namespace_name: "@multi", email_address: "multi@example.com"

    perform_enqueued_jobs do
      gem_push "@multi", file_fixture("peak/peak-0.1.0.gem").binread, token: token
      gem_push "@multi", file_fixture("peak/peak-0.2.0.gem").binread, token: token
    end

    assert_equal %w[0.1.0 0.2.0], compact_index_versions("@multi")["peak"].sort
    assert_equal %w[0.1.0 0.2.0], compact_index_info("@multi", "peak").sort
  end

  private
    def provision_push_token(namespace_name:, email_address:, name: "Owner")
      post user_sign_ups_url, params: { user_sign_up: { name:, email_address:, namespace_name: } }
      user = User.find_by!(email_address:)

      submission = Namespace::Submission.find_by!(name: namespace_name)
      submission.resolve! :approved
      submission.process_approved

      get user_email_verification_url(user.email_verification.token)
      post user_push_keys_url, params: { email_address: }
      user.push_key.token
    end
end
