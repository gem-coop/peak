class Namespace::Mirror < ApplicationRecord
  belongs_to :namespace
  validates :url, presence: true
end
