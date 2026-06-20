ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "httpx/adapters/webmock"
require "openssl"

class ActiveSupport::TestCase
  parallelize workers: :number_of_processors

  include Oaken.test_setup

  def assert_increments(*positionals, by: 1, **explicits, &)
    diffs = explicits.merge(positionals.index_with(by)).transform_keys { _1.method(:count) }
    assert_difference(diffs, &)
  end

  def assert_decrements(*positionals, by: 1, **explicits, &)
    diffs = explicits.merge(positionals.index_with(by)).to_h { [_1.method(:count), -_2] }
    assert_difference(diffs, &)
  end

  def refute_increments(*positionals, &)
    assert_no_difference(positionals.map { _1.method(:count) }, &)
  end

  def oidc_rsa_key = @oidc_rsa_key ||= OpenSSL::PKey::RSA.generate(2048)
  def oidc_jwk = JWT::JWK.new(oidc_rsa_key, kid: "test-kid")

  def stub_oidc_discovery(issuer = OIDC::Provider::GitHubActions::ISSUER)
    WebMock.stub_request(:get, "#{issuer}/.well-known/openid-configuration")
      .to_return(status: 200, body: { jwks_uri: "#{issuer}/jwks" }.to_json,
        headers: { "Content-Type" => "application/json" })
    WebMock.stub_request(:get, "#{issuer}/jwks")
      .to_return(status: 200, body: { keys: [oidc_jwk.export] }.to_json,
        headers: { "Content-Type" => "application/json" })
  end

  def default_github_claims(**overrides)
    {
      "iss" => OIDC::Provider::GitHubActions::ISSUER,
      "aud" => Peak.host,
      "jti" => SecureRandom.uuid,
      "iat" => Time.current.to_i,
      "nbf" => Time.current.to_i,
      "exp" => 5.minutes.from_now.to_i,
      "sub" => "repo:gem-coop/peak:ref:refs/heads/main",
      "repository" => "gem-coop/peak",
      "repository_owner" => "gem-coop",
      "job_workflow_ref" => "gem-coop/peak/.github/workflows/release.yml@refs/heads/main",
      "ref" => "refs/heads/main",
      "environment" => "rubygems"
    }.merge(overrides.transform_keys(&:to_s))
  end

  def build_github_jwt(claims = {})
    JWT.encode(default_github_claims(**claims), oidc_rsa_key, "RS256", kid: oidc_jwk.kid)
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    get sign_in_url(user.magic_link.signed_id)
  end
end
