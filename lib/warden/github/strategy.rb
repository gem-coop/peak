class Warden::GitHub::Strategy < ::Warden::Strategies::Base
  # On first call, we redirect to the authorize URI while stashing state.
  #
  # On the second call, we'll check prerequisites before trading the verification code for an access token.
  #
  # If that code is still valid, we've got an access token that we can make API requests with.
  def authenticate!
    error, state, code = params.symbolize_keys.values_at(:error, :state, :code)
    started = data.present? && state && (error || code)

    if started && (details = trade_authorization(error:, state:, code:))
      success! Warden::GitHub::User.from(**details)
    else
      data["return_to"] = request.url
      data["state"] = state = SecureRandom.hex(20)
      redirect_to oauth.authorize_uri(state:, origin: request.base_url)
    end
  end

  # Called by `success!`'s `after_authentication` hook.
  # Done out of band since Warden doesn't support setting the user and also redirecting at once.
  def finalize
    redirect_to data["return_to"].tap { data.clear }
  end

  private
    def trade_authorization(error:, state:, code:)
      fail! error.tr("_", " ") if error.present?
      fail! "State mismatch"   if data["state"].blank? || data["state"] != state

      oauth.access_token_trade_from(code:).tap { fail! "Bad verification code" unless _1 }
    end

    def redirect_to(uri)
      redirect! uri.to_s
      throw :warden
    end

    def fail!(...)
      data.clear
      super
    end

    def oauth  = Warden::GitHub.oauth
    def data   = session["warden.github.oauth"] ||= {}
end
