class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access"
  has_many :namespaces, through: :accesses
end
