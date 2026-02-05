class User::PushKey < ApplicationRecord
  belongs_to :user
  attribute :expires_at, default: -> { 24.hours.from_now }

  scope :active, -> { where(expires_at: Time.current..).order(expires_at: :desc) }
  scope :expired, -> { where(expires_at: ..Time.current) }
  performs :destroy

  has_secure_token

  def sign_in_mailer
    Mailer.with(push_key: self).sign_in
  end
end
