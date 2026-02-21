class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def set_routed_index(from: Namespace)
      return head :not_found if params[:index] == "private" # TODO: Figure out routing to the /private index.
      @index = from.named(params[:namespace]).indexes.locate_or_external(params[:index])
    end
end
