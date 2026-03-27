class Public::BaseController < ActionController::Base
  private
    def set_routed_index(from: Namespace)
      return head :not_found if params[:index] == "private" # TODO: Figure out routing to the /private index.
      @index = from.approved.named(params[:namespace]).indexes.locate_or_external(params[:index])
    end
end
