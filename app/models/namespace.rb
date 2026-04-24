class Namespace < ApplicationRecord
  has_many :accesses, dependent: :destroy
  has_many :users, through: :accesses

  has_many :indexes, dependent: :destroy
  has_many :gems, through: :indexes
  has_many :versions, class_name: "Gem::Version", through: :gems

  scope :pending,  -> { where(approved_at: nil) }
  scope :approved, -> { where.not(approved_at: nil) }

  has_one :external_index, -> { external_access }, class_name: "Index", dependent: :destroy
  before_create :build_external_index

  # Created & managed by a subscription eventually
  has_one :dev_index, -> { dev_access }, class_name: "Index", dependent: :destroy
  has_one :private_index, -> { private_access }, class_name: "Index", dependent: :destroy

  class_attribute :name_pattern, default: /@[a-z0-9-]+/ # For embedding in HTML5 input patterns.
  normalizes :name, with: -> { _1.start_with?("@") ? _1 : "@#{_1}" }
  validates :name, format: /\A#{name_pattern}\z/, uniqueness: true

  after_create { SlackNotifyNamespaceRequestedJob.perform_later(self) }

  def self.named(name) = find_by!(name:)
  def to_param = name

  def approve
    unless approved_at?
      update! approved_at: Time.current
      mailer.approved.deliver_later
    end
  end
end

# == Schema Information
#
# Table name: namespaces
#
#  id          :bigint           not null, primary key
#  approved_at :datetime
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_namespaces_on_approved_at  (approved_at)
#  index_namespaces_on_name         (name) UNIQUE
#
