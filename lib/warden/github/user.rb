class Warden::GitHub::User < Data.define(:access_token, :expires_at, :refresh_token, :login, :name, :avatar_url)
  def self.from_json(data)
    new(**JSON.parse(data, symbolize_names: true).slice(*members))
  end

  def self.from(access_token:, expires_in:, **)
    expires_at = Time.now.utc.to_i + expires_in.to_i
    details = Warden::GitHub::Client.from(access_token).user_details(members)
    new(access_token:, expires_at:, **, **details)
  end

  def team_member?(**)
    Warden::GitHub::Client.from(access_token).team_member?(login:, **)
  end

  def expired? = Time.at(expires_at).past?

  def name = "@#{login}"
  def avatar = avatar_url
end
