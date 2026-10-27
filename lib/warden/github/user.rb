class Warden::GitHub::User < Data.define(:access_token, :expires_at, :refresh_token, :login, :name, :avatar_url)
  def self.from_json(data)
    new(**JSON.parse(data, symbolize_names: true).slice(*members))
  end

  def self.from(access_token:, **)
    details = Warden::GitHub::Client.from(access_token).user_details(members)
    new(access_token:, **, **details)
  end

  def initialize(expires_in: nil, expires_at: nil, **)
    expires_at ||= Time.now.utc.to_i + expires_in.to_i
    super(expires_at:, **)
  end

  def refreshed
    Warden::GitHub.oauth.refresh(refresh_token)&.then { with(**_1) } if expired?
  end

  def team_member?(**)
    Warden::GitHub::Client.from(access_token).team_member?(login:, **)
  end

  def expired? = Time.at(expires_at).past?

  def handle = "@#{login}"
  def avatar = avatar_url
end
