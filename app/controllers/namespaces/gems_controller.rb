class Namespaces::GemsController < ApplicationController
  skip_forgery_protection only: :create
  before_action :authenticate_index_by_user_push_key, only: :create

  def create
    upload = Current.upload_from(request.body)
    version = @index.gems.version_from name: upload.name, ref: upload.ref

    if version.persisted?
      render plain: "Upload skipped: #{version.package_name} already exists. ❌", status: :conflict
    else
      version.process upload

      render plain: "#{version.package_name} uploaded 🎉"
    end
  end

  def show
    @index = Namespace.named(params[:namespace]).external_index

    gem_name, ref = Peak::Gem.version(params[:id])
    version = @index.versions.for(gem_name).find_by!(ref:)

    if version.package.attached?
      # redirect_to version.package.url expires_in: 5.seconds # TODO: When not using Disk Service?
      send_data version.package.download, filename: version.package_name, disposition: "inline"
    else
      redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
    end
  end

  private
    def authenticate_index_by_user_push_key
      @user = User.find_by!(push_key: request.authorization)
      @index = @user.namespaces.named(params[:namespace]).external_index
    rescue ActiveRecord::RecordNotFound
      if @user
        render plain: "User doesn't have access to the given namespace", status: :unauthorized
      else
        render plain: "API Key is either incorrect or doesn't exist", status: :unauthorized
      end
    end
end
