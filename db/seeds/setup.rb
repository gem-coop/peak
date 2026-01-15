register Namespace::Access, as: :accesses
register Namespace::Gem, as: :gems
register Namespace::Gem::Version, as: :versions

accesses.proxy *Namespace::Access.roles.keys
