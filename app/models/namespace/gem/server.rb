class Namespace::Gem::Server < ActiveRecord::AssociatedObject
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
    mattr_reader :client, default: HTTPX.plugin(:brotli).with(origin: "https://gem.coop")
end
