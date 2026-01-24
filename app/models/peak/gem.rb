class Peak::Gem
  mattr_reader :pattern, default: /[A-Za-z][A-Za-z0-9\.\-\_]+?\.gem/

  def self.version(full_ref)
    full_ref.chomp(".gem").split("-", 2) if pattern.match?(full_ref)
  end
end
