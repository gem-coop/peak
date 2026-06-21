class Namespaces::TokenExchangesController < Public::BaseController
  skip_forgery_protection

  rate_limit to: 10, within: 1.minute, with: :rate_limit_response, only: :create

  def create
    namespace = Namespace.approved.named(params[:namespace])
    key = OIDC::TokenExchange.new(namespace:, jwt: params.require(:jwt)).call

    render json: {
      rubygems_api_key: key.token,
      name: key.name,
      scopes: key.scopes,
      expires_at: key.expires_at.iso8601,
      namespace: namespace.name,
      push_url: namespace_gem_push_url(namespace: namespace.name)
    }
  rescue OIDC::TokenExchange::Error => e
    render json: { error: e.message }, status: :unauthorized
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Unknown namespace" }, status: :not_found
  rescue ActionController::ParameterMissing
    render json: { error: "Missing jwt parameter" }, status: :bad_request
  end

  private
    def rate_limit_response
      render json: { error: "Too many token exchange attempts. Try again later." },
        status: :too_many_requests
    end
end
