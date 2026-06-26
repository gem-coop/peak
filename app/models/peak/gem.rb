class Peak::Gem
  mattr_reader :name_pattern,  default: /[A-Za-z][A-Za-z0-9\.\-\_]+?/
  mattr_reader :route_pattern, default: /#{name_pattern}\.gem/

  # Mirrors RubyGems' validate_name: whole name is [a-zA-Z0-9._-], has a letter, no leading . - _.
  # (Separate from the looser, unanchored name_pattern that route_pattern reuses.)
  mattr_reader :name_format,   default: /\A(?![._-])(?=[a-zA-Z0-9._-]*[a-zA-Z])[a-zA-Z0-9._-]+\z/

  def self.version(ref)
    ref.chomp(".gem").split(/-(?=\d+\.)/) if route_pattern.match?(ref)
  end
end
