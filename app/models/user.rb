class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access"
  has_many :namespaces, through: :accesses

  has_many :acceptances, class_name: "Peak::Terms::Acceptance"
  has_many :terms, class_name: "Peak::Terms", through: :acceptances

  has_many :sessions, dependent: :destroy
  has_one :push_key, dependent: :destroy

  has_object :email_verification
  has_object :magic_link
  before_save { self.email_address_verified_at = nil if email_address_changed? }
  validates_uniqueness_of :email_address

  def system?
    Peak.system_user == self
  end
end
