class Namespace < ApplicationRecord
  has_many :accesses
  has_many :users, through: :accesses

  has_many :gems

  validates_format_of :name, with: /\A@[a-z]+/
end
