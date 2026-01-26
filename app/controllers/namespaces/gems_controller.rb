require "rubygems/package"

class Namespaces::GemsController < ApplicationController
  skip_forgery_protection only: :create
  before_action :set_namespace

  def create
    upload = Current.upload_from(request.body)
    version = @namespace.gems.version_from name: upload.name, ref: upload.ref

    if version.persisted?
      render plain: "#{version.package_name} already exists. Overwrite not allowed ❌", status: :conflict
    else
      version.update! checksum: upload.checksum,
        package: { io: upload.tmpfile, filename: version.package_name }
      render plain: "#{version.package_name} uploaded 🎉"
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
