class ApplicationController < Public::BaseController
  include Authentication
  # require_authentication # TODO: require authentication as needed for our internal controllers.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
