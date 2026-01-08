class Namespace::Access < ApplicationRecord
  belongs_to :namespace
  belongs_to :user

  enum :role, %i[plain owner].index_by(&:itself)
end
