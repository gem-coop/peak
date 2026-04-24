require "test_helper"

class Namespace::AccessTest < ActiveSupport::TestCase
  test "owner" do
    accesses = namespaces.gemcoop.accesses

    assert_equal [users.owner], accesses.owner.extract_associated(:user)
    assert_equal [users.plain], accesses.plain.extract_associated(:user)
  end
end

# == Schema Information
#
# Table name: namespace_accesses
#
#  id           :bigint           not null, primary key
#  role         :string           default("plain"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  namespace_id :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_namespace_accesses_on_namespace_id  (namespace_id)
#  index_namespace_accesses_on_user_id       (user_id)
#
