class Namespace < ApplicationRecord
  has_many :accesses, dependent: :destroy
  has_many :users, through: :accesses

  has_many :indexes, dependent: :destroy
  has_many :gems, through: :indexes
  has_many :versions, class_name: "Gem::Version", through: :gems

  scope :pending,  -> { where(approved_at: nil) }
  scope :approved, -> { where.not(approved_at: nil) }

  has_one :external_index, -> { external_access }, class_name: "Index"
  before_create :build_external_index
  after_create { Slack.notify_namespace(self) }

  # Created & managed by a subscription eventually
  has_one :dev_index, -> { dev_access }, class_name: "Index"
  has_one :private_index, -> { private_access }, class_name: "Index"

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
