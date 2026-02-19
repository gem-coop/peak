class User::EmailVerification < ActiveRecord::AssociatedObject
  def self.find_signed(id, purpose: attribute_name) = super
  def signed_id = super(purpose: self.class.attribute_name)

  def deliver_later
    Mailer.with(verification: self).verification.deliver_later
  end
end
