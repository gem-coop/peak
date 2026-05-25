class Peak::Gem
  mattr_reader :name_pattern,  default: /[A-Za-z][A-Za-z0-9\.\-\_]+?/
  mattr_reader :route_pattern, default: /#{name_pattern}\.gem/

  def self.version(ref)
    ref.chomp(".gem").split(/-(?=\d+\.)/) if route_pattern.match?(ref)
  end
end
