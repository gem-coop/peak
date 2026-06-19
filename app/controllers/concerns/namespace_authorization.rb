module NamespaceAuthorization
  extend ActiveSupport::Concern

  included do
    include Authentication
    require_authentication
    before_action :require_namespace_owner
  end

  private
    def current_namespace
      @namespace ||= Namespace.approved.named(params[:namespace])
    end

    def require_namespace_owner
      unless current_namespace.accesses.owner.exists?(user: Current.user)
        redirect_to namespace_path(current_namespace.name),
          alert: "You must be an owner of #{current_namespace.name} to manage trusted publishers."
      end
    end
end
