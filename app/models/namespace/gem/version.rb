class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  has_one :metadata

  has_many :nodes
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :for, -> { joins(:gem).where(gem: {name: _1}) }

  def to_param = package_name

  def package_name = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"

  def line
    "#{ref} #{references.line}#{metadata&.line}"
  end
end
