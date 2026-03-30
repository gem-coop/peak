class User::MagicLink < ActiveRecord::AssociatedObject
  def self.find_signed!(id) = super(id, purpose: attribute_name)
  def self.find_signed(id)  = super(id, purpose: attribute_name)
  def signed_id(expires_in: 15.minutes) = record.signed_id(purpose: self.class.attribute_name, expires_in:)

  def mailer
    Mailer.with(magic_link: self).sign_in
  end
  delegate :deliver_later, to: :mailer
end
