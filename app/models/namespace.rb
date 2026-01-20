class Namespace < ApplicationRecord
  has_many :accesses
  has_many :users, through: :accesses

  has_many :gems

  validates_format_of :name, with: /\A@[a-z]+\z/

  def self.named(name) = find_by!(name:)
  def to_param = name
end
