register Namespace::Access, as: :accesses
register Namespace::Gem,    as: :gems

accesses.proxy *Namespace::Access.roles.keys
