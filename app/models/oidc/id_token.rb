class OIDC::IdToken < ApplicationRecord
  belongs_to :provider, class_name: "OIDC::Provider"
  belongs_to :trusted_publisher
  belongs_to :push_key, class_name: "TrustedPublisher::PushKey", optional: true

  validates :jti, presence: true, uniqueness: { scope: :provider_id }
end
