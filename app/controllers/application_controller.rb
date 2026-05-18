class ApplicationController < Public::BaseController
  include Authentication
  # require_authentication # TODO: require authentication as needed for our internal controllers.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def echo
    render plain: JSON.pretty_generate({
      params: params.permit!.to_h,
      headers: request.headers.
        group_by{|k,v| k.include?(".") ? k.split(".").first : "HTTP"}.
        transform_values(&:to_h)
    })
  end
end
