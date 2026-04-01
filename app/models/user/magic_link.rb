class User::MagicLink < ActiveRecord::AssociatedObject
  has_mailer to: :user, subject: "Sign in to gem.coop"

  def self.find_signed!(id) = super(id, purpose: attribute_name)
  def self.find_signed(id)  = super(id, purpose: attribute_name)
  def signed_id(expires_in: 15.minutes) = record.signed_id(purpose: self.class.attribute_name, expires_in:)
end
