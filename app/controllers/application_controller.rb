class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def self.block_public_namespace_access(**)
    before_action(**) { head :forbidden if params[:namespace] == "@public" }
  end
end
