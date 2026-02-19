class Namespace < ApplicationRecord
  has_many :accesses
  has_many :users, through: :accesses

  has_many :indexes
  has_many :gems, through: :indexes
  has_many :versions, class_name: "Gem::Version", through: :gems

  has_one :external_index, -> { external_access }, class_name: "Index"
  before_create :build_external_index

  # Created & managed by a subscription eventually
  has_one :dev_index, -> { dev_access }, class_name: "Index"
  has_one :private_index, -> { private_access }, class_name: "Index"

  validates_format_of :name, with: /\A@[a-z-]+\z/
  validates_uniqueness_of :name

  def self.named(name) = find_by!(name:)
  def to_param = name
end
