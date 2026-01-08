class Namespace::Gem::Version::Reference < ApplicationRecord
  belongs_to :source, class_name: module_parent_name
  belongs_to :linked, class_name: module_parent_name

  enum :operator, {
    greater_eq: ">=",
    greater: ">",
    less_eq: "<=",
    less: "<",
    eq: "=",
    pessimistic: "~>",
  }, validate: true

  def part
    "#{operator} #{linked.ref}"
  end
end
