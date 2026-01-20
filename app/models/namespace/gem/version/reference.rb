class Namespace::Gem::Version::Reference < ApplicationRecord
  has_many :nodes, class_name: "#{module_parent}::Node"
  has_many :versions, through: :nodes

  enum :operator, {
    greater_eq: ">=",
    greater: ">",
    less_eq: "<=",
    less: "<",
    eq: "=",
    pessimistic: "~>"
  }

  def self.line
    parts.join(",")
  end

  def self.parts
    all.group_by(&:name).map do |name, refs|
      "#{name}:#{refs.map(&:part).join("&")}"
    end
  end

  def part
    "#{operator_before_type_cast} #{ref}"
  end
end
