class Namespaces::Gems::TrustedPublishersController < ApplicationController
  include NamespaceAuthorization

  before_action :set_gem

  def index
    @trusted_publishers = @gem.trusted_publishers.order(:created_at)
    @trusted_publisher = TrustedPublisher::GitHubActions.new
  end

  def create
    @trusted_publisher = @gem.trusted_publishers.build(
      trusted_publisher_params.merge(
        type: "TrustedPublisher::GitHubActions",
        namespace: current_namespace,
        gem_name: @gem.name,
        provider: OIDC::Provider::GitHubActions.find_by!(issuer: OIDC::Provider::GitHubActions::ISSUER)))

    if @trusted_publisher.save
      redirect_to namespace_gem_trusted_publishers_path(namespace: current_namespace.name, gem_id: @gem.name),
        notice: "Trusted publisher added."
    else
      @trusted_publishers = @gem.trusted_publishers.order(:created_at)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @gem.trusted_publishers.find(params[:id]).destroy!
    redirect_to namespace_gem_trusted_publishers_path(namespace: current_namespace.name, gem_id: @gem.name),
      notice: "Trusted publisher removed."
  end

  private
    def set_gem
      @gem = current_namespace.default_index.gems.named(params[:gem_id])
    end

    def trusted_publisher_params
      params.require(:trusted_publisher).permit(
        :repository_owner, :repository_name, :workflow_filename, :environment, :ref)
    end
end
