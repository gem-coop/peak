class Peak::Gem
  mattr_reader :pattern, default: /[A-Za-z][A-Za-z0-9\.\-\_]+?\.gem/
end
