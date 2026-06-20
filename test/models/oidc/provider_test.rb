require "test_helper"

class OIDC::ProviderTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @provider = oidc_providers.github
  end

  test "for_issuer" do
    assert_equal @provider, OIDC::Provider.for_issuer(OIDC::Provider::GitHubActions::ISSUER)
  end

  test "decode verifies a valid jwt" do
    stub_oidc_discovery
    payload = @provider.decode(build_github_jwt, audience: Peak.host)
    assert_equal "gem-coop/peak", payload["repository"]
  end

  test "decode rejects wrong audience" do
    stub_oidc_discovery
    jwt = build_github_jwt(aud: "wrong.example")
    assert_raises(JWT::InvalidAudError) { @provider.decode(jwt, audience: Peak.host) }
  end

  test "decode rejects expired jwt" do
    stub_oidc_discovery
    jwt = build_github_jwt(exp: 5.minutes.ago.to_i)
    assert_raises(JWT::ExpiredSignature) { @provider.decode(jwt, audience: Peak.host) }
  end

  test "decode rejects bad signature" do
    stub_oidc_discovery
    other = OpenSSL::PKey::RSA.generate(2048)
    jwt = JWT.encode(default_github_claims, other, "RS256", kid: oidc_jwk.kid)
    assert_raises(JWT::DecodeError) { @provider.decode(jwt, audience: Peak.host) }
  end

  test "decode rejects a token missing exp" do
    stub_oidc_discovery
    claims = default_github_claims.except("exp")
    jwt = JWT.encode(claims, oidc_rsa_key, "RS256", kid: oidc_jwk.kid)
    assert_raises(JWT::DecodeError) { @provider.decode(jwt, audience: Peak.host) }
  end

  test "jwks is cached" do
    stub_oidc_discovery
    @provider.jwks
    @provider.jwks
    assert_requested :get, "#{@provider.issuer}/jwks", times: 1
  end
end
