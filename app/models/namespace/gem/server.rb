class Namespace::Gem::Server < ActiveRecord::AssociatedObject
  def download(ref)
    HTTPX.plugin(:brotli).get("https://gem.coop/gems/#{gem.name}-#{ref}.gem").body
  end

  def refs
    info.lines.map { _1.split(" ", 2).first }.without "---"
  end
  def info = CooldownVersion::Server.info(gem.name)

  def versions_json
    CooldownVersion::Server.versions_json(gem.name)
  end
end
