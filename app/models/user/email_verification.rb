class User::EmailVerification < ActiveRecord::AssociatedObject
  def self.find_signed!(id, purpose: attribute_name) = record.find_signed!(id, purpose:)&.email_verification
  def signed_id(expires_in: 6.hours) = record.signed_id(purpose: self.class.attribute_name, expires_in:)

  def verify
    user.update! email_address_verified_at: Time.current unless user.email_address_verified_at?
  end

  def mailer
    Mailer.with(email_verification: self).verification
  end
  delegate :deliver_later, to: :mailer
end
