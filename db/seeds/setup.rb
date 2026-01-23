register Namespace::Access, as: :accesses
register Namespace::Gem, as: :gems
register Namespace::Gem::Version, as: :versions
register Namespace::Gem::Version::Reference, as: :references

accesses.proxy *Namespace::Access.roles.keys

section versions do
  def versions.upload(gem:, ref:)
    version = build(gem:, ref:)
    package = Rails.root.join("test/fixtures/files").join(version.package_name)
    version.update! package: { io: StringIO.new(package.read), filename: version.package_name }
  end

  def versions.by(gem, ref:) = type.find_by!(gem:, ref:)
end
