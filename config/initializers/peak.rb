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

  class Admin < Data.define(:team_id)
    def scope = :admin

    def authenticate(request)
      warden = request.env["warden"]
      team_id && warden.authenticate!(scope:)&.team_member?(team_id)
    end

    def logout(request)
      request.env["warden"].logout(scope:)
    end
  end

  attr_accessor :admin
  @admin = Admin.new(nil)
end
