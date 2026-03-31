class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access", dependent: :destroy
  has_many :namespaces, through: :accesses

  has_many :sessions, dependent: :destroy
  has_one :push_key, dependent: :destroy

  has_object :magic_link, :email_verification
  before_save { self.email_address_verified_at = nil if email_address_changed? }
  validates_uniqueness_of :email_address

  def system?
    Peak.system_user == self
  end
end
