register Namespace::Access, as: :accesses
register Namespace::Gem, as: :gems
register Namespace::Gem::Version, as: :versions
register Namespace::Gem::Version::Reference, as: :references

accesses.proxy *Namespace::Access.roles.keys

def versions.by(gem, ref:)
  type.find_by!(gem:, ref:)
end
