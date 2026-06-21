module ExpiringToken
  extend ActiveSupport::Concern

  included do
    scope :active,  -> { where(expires_at: Time.current..).order(expires_at: :desc) }
    scope :expired, -> { where(expires_at: ..Time.current) }
  end

  def active? = !expired?
  def expired? = expires_at.past?
end
