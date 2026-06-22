class User::EmailVerification < ActiveRecord::AssociatedObject
  has_mailer to: :user, subject: "Verify your email and sign in"

  def self.find_signed!(id) = super(id, purpose: attribute_name)
  def self.find_signed(id)  = super(id, purpose: attribute_name)
  def signed_id(expires_in: 24.hours) = record.signed_id(purpose: self.class.attribute_name, expires_in:)

  def verify
    user.update! email_address_verified_at: Time.current unless verified?
  end
  def verified? = user.verified?
end
