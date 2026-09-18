class Namespace::Gem::Server < ActiveRecord::AssociatedObject
  def gemspec(ref)
    # TODO: Use `load` and pass something so Gem::Specification, Gem::Requirement are valid to parse.
    YAML.unsafe_load client.get("gemspecs/#{gem.name}-#{ref}.gem").body.to_s
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
    mattr_reader :client, default: HTTPX.plugin(:brotli).with(origin: "https://gem.coop")
end
