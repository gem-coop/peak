require "test_helper"

class Namespaces::TokenExchangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.config.action_controller.cache_store.clear
    stub_oidc_discovery
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
  end

  def url = namespace_oidc_exchange_token_url(namespace: namespaces.gemcoop.name)

  test "exchange returns a rubygems-compatible key" do
    post url, params: { jwt: build_github_jwt }
    assert_response :success

    body = JSON.parse(response.body)
    assert body["rubygems_api_key"].start_with?(TrustedPublisher::PushKey::PREFIX)
    assert_equal "trusted-publisher:peak", body["name"]
    assert_equal %w[push_rubygem], body["scopes"]
    assert_equal "@gemcoop", body["namespace"]
    assert_includes body["push_url"], "/@gemcoop/api/v1/gems"
  end

  test "non-matching token is unauthorized" do
    post url, params: { jwt: build_github_jwt(repository: "evil/peak", repository_owner: "evil") }
    assert_response :unauthorized
    assert_equal "No trusted publisher matches this token", JSON.parse(response.body)["error"]
  end

  test "missing jwt is a bad request" do
    post url
    assert_response :bad_request
  end
end
