class ApplicationController < Public::BaseController
  include Authentication
  # require_authentication # TODO: require authentication as needed for our internal controllers.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def self.require_peak_admin_authentication
    http_basic_authenticate_with(name: Peak.admin.username, password: Peak.admin.password)
  end

  def self.set_referrer_policy(policy, **)
    before_action(**) { response.set_header "referrer-policy", policy }
  end

  private
    def set_breadcrumb_trail(*trail)
      @breadcrumb_trail = trail
    end
end
