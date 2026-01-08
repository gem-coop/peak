class Namespace::Gem::Version::Reference < ApplicationRecord
  belongs_to :source, class_name: module_parent_name
  belongs_to :linked, class_name: module_parent_name
  has_one :gem, through: :linked

  enum :operator, {
    greater_eq: ">=",
    greater: ">",
    less_eq: "<=",
    less: "<",
    eq: "=",
    pessimistic: "~>"
  }, validate: true

  def self.line_parts
    includes(linked: :gem).group_by(&:gem).map do |gem, refs|
      "#{gem.name}:#{refs.map(&:part).join("&")}"
    end
  end

  def part
    # need the serialized version of the operator lol
    "#{self.class.operators[operator]} #{linked.ref}"
  end
end
