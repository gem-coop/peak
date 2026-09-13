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

    # Inject above ActionController::BasicImplicitRender#send_action so we can capture and render the return value if it's renderable.
    ActionController::BasicImplicitRender.include Module.new {
      def send_action(...)
        super.tap { |ret| render ret if !performed? && ret.respond_to?(:render_in) }
      end
    }
end
