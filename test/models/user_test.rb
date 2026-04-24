require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "system?" do
    refute users.owner.system?
    refute users.plain.system?
    assert users.system.system?
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
