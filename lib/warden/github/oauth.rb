class Warden::GitHub::OAuth < Data.define(:client_id, :client_secret, :scope, :redirect_uri)
  def initialize(client_id:, client_secret:, **)
    raise ArgumentError, "missing client_id"     if client_id.blank?
    raise ArgumentError, "missing client_secret" if client_secret.blank?
    super
  end

  def authorize_uri(origin:, state:)
    redirect_uri = URI(origin).tap { _1.path = self.redirect_uri }.to_s

    URI("https://github.com/login/oauth/authorize").tap do
      _1.query = URI.encode_www_form(client_id:, scope:, redirect_uri:, state:)
    end
  end

  def access_token_trade_from(code:)
    data = HTTPX.post("https://github.com/login/oauth/access_token", form: { client_id:, client_secret:, code: }).form
    data.symbolize_keys.slice(:access_token, :expires_in, :refresh_token).presence
  end
end
