class Namespaces::GemsController < Public::BaseController
  include ActiveStorage::Streaming

  skip_forgery_protection only: :create
  before_action :halt_exhaustive_upload, :set_user_from_push_key, only: :create

  def create
    upload = Current.upload_from(request.body).validate
    version = @index.gems.version_from name: upload.name, ref: upload.platform_ref

    if version.persisted?
      render plain: "Upload skipped: #{version.package_name} already exists. ❌", status: :conflict
    else
      version.process upload, created_by: @user

      render plain: "#{version.package_name} uploaded 🎉"
    end
  rescue Peak::Gem::Upload::InvalidError
    render plain: "Upload rejected: gemspec contains invalid characters. ❌", status: :unprocessable_entity
  end

  def show
    set_routed_index

    gem_name, ref = Peak::Gem.version(params[:id])
    version = @index.versions.with_attached_package.for(gem_name).find_by!(ref:)

    case
    when (blob = version.package.blob).nil?
      redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true

    # Adapted from ActiveStorage::Blobs::ProxyController:
    # https://github.com/rails/rails/blob/9ecc4a5ca6fb9a93a1f243e8f23d8ba592f41600/activestorage/app/controllers/active_storage/blobs/proxy_controller.rb#L28
    when ranges = request.get_header("Range").presence
      send_blob_byte_range_data blob, ranges
    else
      expires_in 1.year, public: @index.public_access?

      response.headers["accept-ranges"]  = "bytes"
      response.headers["content-length"] = blob.byte_size.to_s

      send_blob_stream blob, disposition: "inline"
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
