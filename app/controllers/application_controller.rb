class ApplicationController < Public::BaseController
  include Authentication
  # require_authentication # TODO: require authentication as needed for our internal controllers.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  skip_before_action :verify_authenticity_token, only: [:echo]
  def echo
    render plain: JSON.pretty_generate({
      csrf: {
        valid_origin: valid_request_origin?,
        valid_token: any_authenticity_token_valid?,
        form_param: form_authenticity_token,
        header: request.x_csrf_token
      },
      session: session.to_h,
      request: {
        base_url: request.base_url,
        origin: request.origin,
        host: request.host
      },
      params: params.permit!.to_h,
      headers: request.headers.select { |k, v| !k.include?(".") }.sort_by(&:first).to_h
    })
  end
end
