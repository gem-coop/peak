class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access"
  has_many :namespaces, through: :accesses

  has_one :push_key, dependent: :destroy

  has_object :email_verification
  validates_uniqueness_of :email_address

  def system?
    Peak.system_user == self
  end
end
