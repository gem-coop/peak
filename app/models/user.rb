class User < ApplicationRecord
  has_many :submissions, class_name: "Namespace::Submission", foreign_key: :owner_id

  has_many :accesses, class_name: "Namespace::Access", dependent: :destroy
  has_many :namespaces, through: :accesses

  has_many :acceptances, class_name: "Peak::Terms::Acceptance"
  has_many :terms, class_name: "Peak::Terms", through: :acceptances

  has_many :sessions, dependent: :destroy
  has_one :push_key, dependent: :destroy

  has_object :magic_link, :email_verification
  before_update { self.email_address_verified_at = nil if email_address_changed? }
  validates_uniqueness_of :email_address

  # Keyed on the verified-at timestamp so the link self-invalidates once the email is verified.
  generates_token_for :email_verification, expires_in: 24.hours do
    email_address_verified_at&.to_i
  end

  def verified? = email_address_verified_at?

  def system?
    Peak.system_user == self
  end
end
