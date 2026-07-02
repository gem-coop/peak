module Peak extend self
  def table_name_prefix = "peak_"

  Release = Data.define(:sha)
  sha = ENV.fetch("GIT_SHA") { `git rev-parse HEAD`.chomp }
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
  def Error(...) = Error.new(...)

  Admin = Data.define :username, :password do
    def authenticate(username_challenge, password_challenge)
      # Use `&` to not short-circuit.
      compare(username, username_challenge) & compare(password, password_challenge)
    end

    def compare(internal, other)
      internal.present? && ActiveSupport::SecurityUtils.secure_compare(internal, other)
    end
  end

  password = ENV["ADMIN_PASSWORD"]
  password ||= "password" if Rails.env.local?
  admin = Admin.new(ENV.fetch("ADMIN_USERNAME", "gem-coop"), password)
  define_method :admin, &admin.method(:itself)
end
