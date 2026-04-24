class Public::BaseController < ActionController::Base
  layout "application"

  private
    def set_routed_index(from: Namespace)
      # TODO: Figure out authenticated routing to `private_access` indexes.
      @index = from.approved.named(params[:namespace]).indexes.public_access.locate_or_default(params[:index])
    end
end
