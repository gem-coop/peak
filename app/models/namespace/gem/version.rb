class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  has_one :metadata

  has_many :nodes
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  def line
    "#{ref} #{references.line}#{metadata&.line}"
  end
end
