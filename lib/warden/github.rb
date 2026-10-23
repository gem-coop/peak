# Adapted from https://gem.coop/@rubygems/warden-github where the repo no longer exists.
module Warden::GitHub
  autoload :OAuth,    "warden/github/oauth"
  autoload :User,     "warden/github/user"
  autoload :Strategy, "warden/github/strategy"

  singleton_class.attr_accessor :oauth

  class Client < Data.define(:client)
    def self.from(token)
      new HTTPX.with(origin: "https://api.github.com").plugin(:response_cache, response_cache_store: :file_store).plugin(:auth).bearer_auth(token)
    end

    def user_details(keys)
      client.get("/user").json(symbolize_names: true).slice(*keys)
    end

    def team_member?(...)
      team_membership(...).json["state"] == "active"
    end
    def team_membership(org:, team:, login:) = client.get("/orgs/#{org}/teams/#{team}/memberships/#{login}")
  end

  Warden::Strategies.add :github, Strategy
  Warden::Manager.after_authentication { |user, auth, options| auth.winning_strategy.try(:finalize) }

  def self.serialize_with(scope, verifier)
    Warden::Manager.serialize_into_session(scope) { |user| verifier.generate(user.to_json) }
    Warden::Manager.serialize_from_session(scope) { |key| data = verifier.verified(key) and Warden::GitHub::User.from_json(data) }
  end
end
