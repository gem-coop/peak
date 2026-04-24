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

  def self.ids_from(triples)
    upsert_all triples.map { {name: _1, operator: _2, ref: _3} }
  end

  def self.upsert_all(values)
    # Also collect already inserted ids with `update_only: :ref`.
    super(values, update_only: :ref, returning: :id,
      unique_by: :namespace_gem_version_references_uniqueness).rows.flat_map(&:first)
  end

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

# == Schema Information
#
# Table name: namespace_gem_version_references
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  operator   :string           not null
#  ref        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_namespace_gem_version_references_on_name  (name)
#  namespace_gem_version_references_uniqueness     (name,operator,ref) UNIQUE
#
