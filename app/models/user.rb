class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access"
  has_many :namespaces, through: :accesses

  has_secure_token :push_key, length: 32
  generates_token_for :push_key_install, expires_in: 6.hours
  def push_key_install_token = generate_token_for(:push_key_install)
end
