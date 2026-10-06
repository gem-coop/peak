Warden::GitHub::Rails.setup do |config|
  config.default_scope = :admin

  config.add_scope :admin,
    client_id: ENV["GITHUB_APP_CLIENT_ID"],
    client_secret: ENV["GITHUB_APP_CLIENT_SECRET"],
    scope: "read:org",
    redirect_uri: "/admin/callback/github"

  # github.com/orgs/gem-coop/teams/maintainers
  config.add_team :maintainers, ENV.fetch("GITHUB_ADMIN_TEAM_ID", 0)
end
