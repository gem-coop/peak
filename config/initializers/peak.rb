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
      Current.admin = User.new(warden.authenticate!(scope:))
      Current.admin.team_member?(team_id)
    end

    def logout(request)
      request.env["warden"].logout(scope:)
    end

    class User < Data.define(:github_user)
      def team_member?(team_id)
        team_id && github_user&.team_member?(team_id)
      end

      def name
        "@#{github_user.login}"
      end

      def avo_title
        github_user.name
      end

      def avatar
        github_user.avatar_url
      end
    end
  end

  attr_accessor :admin
  @admin = Admin.new(nil)
end
