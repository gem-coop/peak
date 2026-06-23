class Namespaces::GemsController < Public::BaseController
  skip_forgery_protection only: :create
  before_action :halt_exhaustive_upload, :set_user_from_push_key, only: :create

  def create
    upload = Current.upload_from(request.body)
    version = @index.gems.version_from name: upload.name, ref: upload.platform_ref

    if version.persisted?
      render plain: "Upload skipped: #{version.package_name} already exists. ❌", status: :conflict
    else
      version.process upload, created_by: @user

      render plain: "#{version.package_name} uploaded 🎉"
    end
  end

  def show
    set_routed_index

    gem_name, ref = Peak::Gem.version(params[:id])
    version = @index.versions.for(gem_name).find_by!(ref:)

    if version.package.attached?
      expires_in 1.year, public: @index.public_access?

      # redirect_to version.package.url expires_in: 5.seconds # TODO: When not using Disk Service?
      send_data version.package.download, filename: version.package_name, disposition: "inline"
    else
      redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
    end
  end

  private
    def halt_exhaustive_upload
      head :bad_request if request.content_length > Peak::Gem::Upload.limit
    end

    def set_user_from_push_key
      @user = User::PushKey.from(push_key_token).user

      case
      when @user.nil?
        render plain: "API Key is either incorrect or doesn't exist", status: :unauthorized
      when !@user.verified?
        render plain: "User needs to verify email address", status: :unauthorized
      else
        set_routed_index_from_user @user
      end
    end

    def push_key_token
      request.authorization.delete_prefix("Bearer ")
    end
end
