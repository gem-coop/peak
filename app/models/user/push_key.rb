class User::PushKey < ApplicationRecord
  belongs_to :user
  attribute :expires_at, default: -> { 24.hours.from_now }

  scope :active, -> { where(expires_at: Time.current..).order(expires_at: :desc) }
  scope :expired, -> { where(expires_at: ..Time.current) }
  performs :destroy

  has_secure_token

  def active? = !expired?
  def expired? = expires_at.past?

  def sign_in_mailer
    Mailer.with(push_key: self).sign_in
  end
end

# == Schema Information
#
# Table name: user_push_keys
#
#  id         :bigint           not null, primary key
#  expires_at :datetime         not null
#  token      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_push_keys_on_user_id  (user_id)
#
