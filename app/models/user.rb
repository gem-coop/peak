class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access"
  has_many :namespaces, through: :accesses

  has_secure_token :push_key, length: 32
end
