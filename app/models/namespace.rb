class Namespace < ApplicationRecord
  has_many :accesses, dependent: :destroy
  has_many :users, through: :accesses

  has_many :indexes, dependent: :destroy
  has_one_built :default_index, -> { public_access.where(slug: :default) }, class_name: "Index"

  scope :pending,  -> { where(approved_at: nil) }
  scope :approved, -> { where.not(approved_at: nil) }

  after_create { SlackNotifyNamespaceRequestedJob.perform_later(self) }

  class_attribute :name_pattern, default: /@[a-z0-9-]+/ # For embedding in HTML5 input patterns.
  normalizes :name, with: -> { _1.start_with?("@") ? _1 : "@#{_1}" }
  validates :name, format: /\A#{name_pattern}\z/, uniqueness: true

  def self.named(name) = find_by!(name:)
  def to_param = name

  def approve
    unless approved_at?
      update! approved_at: Time.current
      mailer.approved.deliver_later
    end
  end
end
