class Namespaces::GemsController < Public::BaseController
  skip_forgery_protection only: :create
  before_action :authenticate_push, only: :create

  def create
    upload = Current.upload_from(request.body)

    if @trusted_publisher && upload.name != @trusted_publisher.gem_name
      return render plain: "Token is scoped to #{@trusted_publisher.gem_name}, not #{upload.name}. ❌",
        status: :forbidden
    end

    version = @index.gems.version_from name: upload.name, ref: upload.platform_ref

    if version.persisted?
      render plain: "Upload skipped: #{version.package_name} already exists. ❌", status: :conflict
    else
      version.process upload, created_by: @actor
      @trusted_publisher&.link_gem!(version.gem)

      render plain: "#{version.package_name} uploaded 🎉"
    end
  end

  def show
    set_routed_index

    gem_name, ref = Peak::Gem.version(params[:id])
    version = @index.versions.for(gem_name).find_by!(ref:)

    if version.package.attached?
      expires_in 1.year, public: @index.public_access?

      send_data version.package.download, filename: version.package_name, disposition: "inline"
    else
      redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
    end
  end

  private
    def authenticate_push
      token = request.authorization.to_s.delete_prefix("Bearer ")
      if token.start_with?(TrustedPublisher::PushKey::PREFIX)
        authenticate_by_trusted_publisher(token)
      else
        authenticate_index_by_user_push_key(token)
      end
    end

    def authenticate_by_trusted_publisher(token)
      key = TrustedPublisher::PushKey.active.find_by!(token_digest: TrustedPublisher::PushKey.digest(token))
      @trusted_publisher = key.trusted_publisher
      @actor = @trusted_publisher

      if @trusted_publisher.namespace.name != params[:namespace]
        return render plain: "Token is not valid for #{params[:namespace]}. ❌", status: :unauthorized
      end

      @index = @trusted_publisher.target_index
    rescue ActiveRecord::RecordNotFound
      render plain: "API Key is either incorrect or doesn't exist", status: :unauthorized
    end

    def authenticate_index_by_user_push_key(token)
      @actor = User::PushKey.active.find_by!(token:).user
      set_routed_index from: @actor.namespaces
    rescue ActiveRecord::RecordNotFound
      if @actor
        render plain: "User doesn't have access to the given namespace", status: :unauthorized
      else
        render plain: "API Key is either incorrect or doesn't exist", status: :unauthorized
      end
    end
end
