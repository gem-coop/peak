class Namespace::Gem::Server < ActiveRecord::AssociatedObject
  def gemspec(ref)
    body = client.get("quick/Marshal.4.8/#{gem.name}-#{ref}.gemspec.rz").body.to_s
    require "rubygems/safe_marshal"
    Gem::SafeMarshal.safe_load Gem::Util.inflate(body)
  end

  def download(ref)
    client.get("gems/#{gem.name}-#{ref}.gem").body
  end

  def refs
    info.lines.map { _1.split(" ", 2).first }.without "---"
  end
  def info = client.get("/info/#{gem.name}").body.to_s

  def versions_json
    client.get("/api/v1/versions/#{gem.name}.json").json
  end

  private
    mattr_reader :client, default: HTTPX.plugin(:persistent).with(origin: "https://rubygems.org")
end
