class Peak::Gem
  mattr_reader :pattern, default: /[A-Za-z][A-Za-z0-9\.\-\_]+?\.gem/

  def self.version(full_ref)
    if pattern.match?(full_ref)
      ref = full_ref.chomp(".gem")
      ref.rindex("-").then { [ref.byteslice(..._1), ref.byteslice(_1.succ..)] }
    end
  end
end
