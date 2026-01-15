class Namespace::Gem < ApplicationRecord
  belongs_to :namespace
  has_many :versions
end
