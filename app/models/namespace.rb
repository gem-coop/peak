class Namespace < ApplicationRecord
  has_many :accesses
  has_many :users, through: :accesses

  has_many :indexes
  has_many :gems, through: :indexes
  has_many :versions, class_name: "Gem::Version", through: :gems

  has_one :external_index, -> { external_access }, class_name: "Index"
  has_one :internal_index, -> { internal_access }, class_name: "Index" # Created & managed by a subscription eventually
  before_create :build_external_index

  validates_format_of :name, with: /\A@[a-z-]+\z/

  def self.named(name) = find_by!(name:)
  def to_param = name
end
