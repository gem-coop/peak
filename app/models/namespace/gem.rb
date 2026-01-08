class Namespace::Gem < ApplicationRecord
  belongs_to :namespace
  has_many :versions

  has_object :line
end
