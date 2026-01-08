register Namespace::Access, as: :accesses
register Namespace::Gem,    as: :gems

accesses.proxy *Namespace::Access.roles.keys

def gems.parse(name, *lines)
  gem = create(name, name:, unique_by: [:namespace_id, :name])
  lines.map { gem.line.parse _1 }
end
