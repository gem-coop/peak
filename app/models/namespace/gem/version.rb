class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  has_one :metadata

  has_many :references, foreign_key: :source_id
  has_many :reverse_references, foreign_key: :linked_id

  has_object :line
end
