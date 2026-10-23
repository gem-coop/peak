module Peak extend self
  def table_name_prefix = "peak_"

  Release = Data.define(:sha)
  sha = ENV.fetch("GIT_SHA") { `git rev-parse HEAD 2> /dev/null || jj log -r @ -T change_id -G`.chomp }
  mattr_reader :release, default: Release.new(sha:)

  def host
    Rails.application.routes.default_url_options[:host]
  end

  def env
    @env ||= ActiveSupport::EnvironmentInquirer.new ENV.fetch("PEAK_ENV") {
      Rails.env.test? ? "test" : "development"
    }
  end

  singleton_class.attr_reader :env_tag
  @env_tag = env.production? ? "" : "[#{env.upcase}] "

  def system_user
    @system_user ||= User.create_with(name: "gem.coop system").find_or_create_by!(email_address: "support@gem.coop")
  end

  def Status(...) = Status.new(...)
  def Ok(...) = Ok.new(...)
  def Error(...) = Error.new(...)

  class Peak::Admin < Data.define(:org, :team, :client_id, :client_secret)
    def self.empty = new(**members.index_with(nil))

    def scope = :admin
    def client_set? = client_id.present? && client_secret.present?

    def authenticate(request)
      warden = request.env["warden"]
      logout request if warden.user(scope:)&.expired?

      Current.admin = warden.authenticate!(scope:)
      Current.admin&.team_member?(org:, team:)
    end

    def logout(request)
      request.env["warden"].logout(scope)
    end
  end

  attr_accessor :admin
  @admin = Admin.empty
end
