class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  has_one :metadata
end
