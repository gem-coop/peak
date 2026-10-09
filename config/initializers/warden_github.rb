# Adapted from Warden::GitHub::Verifier to allow us to inject a verifier directly.
class Peak::Admin::UserSerializer < Data.define(:const, :verifier)
  def dump(user)
    verifier.generate(user.marshal_dump)
  end

  def load(key)
    data = verifier.verified(key) and const.new.tap { _1.marshal_load data }
  end
end

# github.com/orgs/gem-coop/teams/maintainers
Peak.admin = Peak::Admin.new(team_id: ENV.fetch("GITHUB_ADMIN_TEAM_ID", nil))

Rails.application.config.middleware.use Warden::Manager do |config|
  config.intercept_401 = false
  config.failure_app = ->(env) { [403, {}, [env["warden"].message]] }

  # Fix that warden-github-rails didn't use verification like Warden::GitHub wanted.
  serializer = Peak::Admin::UserSerializer.new Warden::GitHub::User, Rails.application.message_verifier("warden_github")

  scope = Peak.admin.scope
  config.serialize_from_session(scope) { |key| serializer.load(key) }
  config.serialize_into_session(scope) { |user| serializer.dump(user) }

  config.scope_defaults scope, strategies: [:github], config: {
    client_id: ENV["GITHUB_APP_CLIENT_ID"],
    client_secret: ENV["GITHUB_APP_CLIENT_SECRET"],
    scope: "read:org",
    redirect_uri: "/admin/callback/github"
  }
end
