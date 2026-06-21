require "test_helper"

class OIDC::TokenExchangeTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    stub_oidc_discovery
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
  end

  def exchange(jwt) = OIDC::TokenExchange.new(namespace: namespaces.gemcoop, jwt:).call

  test "mints a scoped key on a matching token" do
    key = exchange(build_github_jwt)
    assert_kind_of TrustedPublisher::PushKey, key
    assert_equal @publisher, key.trusted_publisher
    assert key.token.start_with?(TrustedPublisher::PushKey::PREFIX)
    assert_equal 1, OIDC::IdToken.count
  end

  test "raises when no publisher matches" do
    jwt = build_github_jwt(repository: "evil/peak", repository_owner: "evil")
    assert_raises(OIDC::TokenExchange::Error) { exchange(jwt) }
  end

  test "rejects a replayed jti" do
    jwt = build_github_jwt
    exchange(jwt)
    assert_raises(OIDC::TokenExchange::Error) { exchange(jwt) }
  end

  test "rejects ambiguous matches" do
    # The uniqueness validation normally prevents duplicates; bypass it to prove
    # match_publisher still refuses to mint when two publishers match a token.
    TrustedPublisher::GitHubActions.new(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml"
    ).save!(validate: false)
    assert_raises(OIDC::TokenExchange::Error) { exchange(build_github_jwt) }
  end

  test "concurrent replay raises TokenExchange::Error not RecordNotUnique" do
    jwt = build_github_jwt(jti: "fixed-jti-race")
    exchange(jwt)
    # Simulate a second request that slipped past guard_replay! before the first committed.
    # Bypass the soft guard check; the existing row triggers a uniqueness error in mint.
    no_guard_exchange = Class.new(OIDC::TokenExchange) { def guard_replay!(...) = nil }
    assert_raises(OIDC::TokenExchange::Error) do
      no_guard_exchange.new(namespace: namespaces.gemcoop, jwt:).call
    end
  end

  test "rejects an unknown issuer" do
    jwt = JWT.encode(default_github_claims(iss: "https://evil.example"), oidc_rsa_key, "RS256")
    assert_raises(OIDC::TokenExchange::Error) { exchange(jwt) }
  end
end
