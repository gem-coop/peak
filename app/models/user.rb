class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access"
  has_many :namespaces, through: :accesses

  has_one :push_key, dependent: :destroy

  def system?
    Peak.system_user == self
  end
end
