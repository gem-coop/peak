class Namespace < ApplicationRecord
  has_many :accesses
  has_many :users, through: :accesses
end
