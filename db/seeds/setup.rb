Oaken::Stored::ActiveRecord.include loader.context
def fixture_upload(filename) = Peak::Gem::Upload.read(fixture_file(filename))
def fixture_file(filename)   = Rails.root.join("test/fixtures/files").join(filename)

register Namespace::Access, as: :accesses
register Namespace::Gem, as: :gems
register Namespace::Gem::Version, as: :versions
register Namespace::Gem::Version::Reference, as: :references

accesses.proxy *Namespace::Access.roles.keys

versions.with do
  def upload(gem, ref:)
    build(gem:, ref:).tap { _1.process fixture_upload("#{gem.name}/#{_1.filename}") }
  end

  def by(gem, ref:) = type.find_by!(gem:, ref:)
end
