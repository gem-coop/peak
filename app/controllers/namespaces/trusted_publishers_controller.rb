class Namespaces::TrustedPublishersController < ApplicationController
  include NamespaceAuthorization

  def index
    @trusted_publishers = current_namespace.trusted_publishers.pending.order(:created_at)
    @trusted_publisher = TrustedPublisher::GitHubActions.new
  end

  def create
    @trusted_publisher = current_namespace.trusted_publishers.build(
      trusted_publisher_params.merge(
        type: "TrustedPublisher::GitHubActions",
        provider: OIDC::Provider::GitHubActions.sole))

    if @trusted_publisher.save
      redirect_to namespace_trusted_publishers_path(namespace: current_namespace.name),
        notice: "Pending trusted publisher added."
    else
      @trusted_publishers = current_namespace.trusted_publishers.pending.order(:created_at)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    current_namespace.trusted_publishers.pending.find(params[:id]).destroy!
    redirect_to namespace_trusted_publishers_path(namespace: current_namespace.name),
      notice: "Pending trusted publisher removed."
  end

  private
    def trusted_publisher_params
      params.require(:trusted_publisher).permit(
        :gem_name, :repository_owner, :repository_name, :workflow_filename, :environment, :ref)
    end
end
