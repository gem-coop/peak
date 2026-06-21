class OIDC::TokenExchange
  class Error < StandardError; end

  def initialize(namespace:, jwt:, audience: Peak.host)
    @namespace = namespace
    @jwt = jwt
    @audience = audience
  end

  def call
    provider = resolve_provider
    claims = verify(provider, @jwt)
    guard_replay!(provider, claims)
    publisher = match_publisher(claims)
    mint(provider, publisher, claims)
  end

  private
    def resolve_provider
      payload, = JWT.decode(@jwt, nil, false)
      OIDC::Provider.for_issuer(payload["iss"])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      raise Error, "Unknown or malformed token issuer"
    end

    def verify(provider, jwt)
      provider.decode(jwt, audience: @audience)
    rescue JWT::DecodeError => e
      raise Error, "Token verification failed: #{e.message}"
    end

    def guard_replay!(provider, claims)
      if OIDC::IdToken.exists?(provider:, jti: claims["jti"])
        raise Error, "Token has already been used"
      end
    end

    def match_publisher(claims)
      candidates = @namespace.trusted_publishers.select { _1.matches?(claims) }
      raise Error, "No trusted publisher matches this token" if candidates.empty?
      raise Error, "Token matches multiple trusted publishers" if candidates.size > 1
      candidates.first
    end

    def mint(provider, publisher, claims)
      key = nil
      OIDC::IdToken.transaction do
        key = publisher.push_keys.create!
        OIDC::IdToken.create!(provider:, trusted_publisher: publisher,
          push_key: key, jti: claims["jti"], claims:)
      end
      key
    rescue ActiveRecord::RecordNotUnique
      raise Error, "Token has already been used"
    rescue ActiveRecord::RecordInvalid => e
      raise Error, "Token has already been used" if e.record.errors[:jti].any?
      raise
    end
end
