# github.com/orgs/gem-coop/teams/maintainers
org  = ENV.fetch("GITHUB_ADMIN_ORG_NAME", "gem-coop")
team = ENV.fetch("GITHUB_ADMIN_TEAM_NAME", "maintainers")

client_id = ENV["GITHUB_APP_CLIENT_ID"]
client_secret = ENV["GITHUB_APP_CLIENT_SECRET"]

Peak.admin = Peak::Admin.new(org:, team:, client_id:, client_secret:)
return unless Peak.admin.client_set?

require_relative "../../lib/warden/github"

Warden::GitHub::User.alias_method :avo_title, :name
Warden::GitHub.oauth = Warden::GitHub::OAuth.new(
  client_id:,
  client_secret:,
  scope: "read:org",
  redirect_uri: "/admin/callback/github"
)

Rails.application.config.middleware.use Warden::Manager do |config|
  config.intercept_401 = false
  config.failure_app = ->(env) { [403, {}, [env["warden"].message]] }

  scope = Peak.admin.scope
  config.scope_defaults scope, strategies: [:github]
  Warden::GitHub.serialize_with scope, Rails.application.message_verifier(:peak_admin)
end
