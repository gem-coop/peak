class User::EmailVerification < ActiveRecord::AssociatedObject
  has_mailer to: :user, subject: "Verify your email and sign in"

  def self.find_by_token(token) = User.find_by_token_for(attribute_name, token)&.email_verification
  def token = user.generate_token_for(self.class.attribute_name)

  def verify
    user.update! email_address_verified_at: Time.current unless verified?
  end
  def verified? = user.verified?
end
