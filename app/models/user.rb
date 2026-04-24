class User < ApplicationRecord
  has_many :accesses, class_name: "Namespace::Access", dependent: :destroy
  has_many :namespaces, through: :accesses

  has_many :acceptances, class_name: "Peak::Terms::Acceptance"
  has_many :terms, class_name: "Peak::Terms", through: :acceptances

  has_many :sessions, dependent: :destroy
  has_one :push_key, dependent: :destroy

  has_object :magic_link, :email_verification
  before_save { self.email_address_verified_at = nil if email_address_changed? }
  validates_uniqueness_of :email_address

  def system?
    Peak.system_user == self
  end
end

# == Schema Information
#
# Table name: users
#
#  id                        :bigint           not null, primary key
#  email_address             :string           not null
#  email_address_verified_at :datetime
#  name                      :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
