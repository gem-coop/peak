require "rubygems/package"

class Namespaces::GemsController < ApplicationController
  skip_forgery_protection only: :create
  before_action :set_namespace

  def create
    spec = Peak::Gem.spec_from(request.body)

    gem = @namespace.gems.find_or_create_by!(name: spec.name)
    version = gem.versions.find_or_initialize_by(ref: spec.version.to_s)

    if version.persisted?
      head :bad_request
    else
      version.update! package: { io: request.body, filename: version.package_name }
    end
  end

  def show
    gem_name, ref = Peak::Gem.version(params[:id])
    version = @namespace.versions.for(gem_name).find_by!(ref:)

    if version.package.attached?
      # redirect_to version.package.url expires_in: 5.seconds # TODO: When not using Disk Service?
      send_data version.package.download, filename: version.package_name, disposition: "inline"
    else
      redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
    end
  end

  private
    def set_namespace
      @namespace = Namespace.named(params[:namespace])
    end
end
