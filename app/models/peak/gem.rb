class Peak::Gem
  mattr_reader :unanchored_name_pattern, default: /[A-Za-z0-9][A-Za-z0-9\.\-\_]+/
  mattr_reader :name_pattern,  default: /\A#{unanchored_name_pattern}\z/
  mattr_reader :route_pattern, default: /#{unanchored_name_pattern}\.gem/ # Routes manage anchoring.

  mattr_reader :operators, default: {
    greater_eq: ">=",
    greater: ">",
    less_eq: "<=",
    less: "<",
    eq: "=",
    not_eq: "!=",
    pessimistic: "~>"
  }
  mattr_reader :operator_values, default: Set.new(operators.values)

  def self.name?(name)
    name_pattern.match? name
  end

  def self.version(ref)
    ref.chomp(".gem").split(/-(?=\d+\.)/) if route_pattern.match?(ref)
  end
end
