class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access"
  has_many :namespaces, through: :accesses

  has_one :push_key, dependent: :destroy

  has_object :email_verification
  before_save { self.email_address_verified_at = nil if email_address_changed? }
  after_create { Slack.notify "#{name} <#{email_address}> signed up!" }
  validates_uniqueness_of :email_address

  def system?
    Peak.system_user == self
  end
end
