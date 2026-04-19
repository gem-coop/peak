class Namespace::Gem::Server < ActiveRecord::AssociatedObject
  def upstream
    @upstream ||= Namespace::Index::Mirror.new(upstream_url: "https://rubygems.org").upstream
  end

  def refs
    info.lines.map { _1.split(" ", 2).first }.without "---"
  end

  def info = upstream.info(gem.name)
  def versions_json = upstream.versions_json(gem.name)
  def download(ref) = upstream.download(gem.name, ref)
end
