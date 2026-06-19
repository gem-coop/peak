class OIDC::Provider < ApplicationRecord
  has_many :trusted_publishers, dependent: :restrict_with_exception

  JWKS_CACHE_TTL = 5.minutes

  def self.for_issuer(issuer) = find_by!(issuer:)

  # Verifies signature (RS256), issuer, audience, and time claims; returns the decoded payload.
  def decode(jwt, audience:)
    payload, _header = JWT.decode(jwt, nil, true,
      algorithms: %w[RS256],
      jwks: jwks,
      iss: issuer, verify_iss: true,
      aud: audience, verify_aud: true,
      verify_expiration: true,
      verify_not_before: true,
      verify_iat: true)
    payload
  end

  def jwks
    Rails.cache.fetch("oidc/jwks/#{issuer}", expires_in: JWKS_CACHE_TTL) do
      fetch_json(discovery.fetch("jwks_uri"))
    end
  end

  private
    def discovery
      fetch_json("#{issuer}/.well-known/openid-configuration")
    end

    def fetch_json(url)
      response = HTTPX.get(url)
      raise JWT::DecodeError, "OIDC fetch failed: #{url} (#{response.status})" unless response.status == 200
      JSON.parse(response.body.to_s)
    end
end
