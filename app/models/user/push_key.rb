class User::PushKey < ApplicationRecord
  include ExpiringToken

  belongs_to :user
  attribute :expires_at, default: -> { 24.hours.from_now }

  performs :destroy

  has_secure_token

  def sign_in_mailer
    Mailer.with(push_key: self).sign_in
  end
end
