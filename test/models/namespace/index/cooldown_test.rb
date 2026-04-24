require "test_helper"

class Namespace::Index::CooldownTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: namespace_index_cooldowns
#
#  id                :bigint           not null, primary key
#  days_delayed      :integer          default(2), not null
#  last_compacted_at :datetime         not null
#  versions_contents :text             default("---\n"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  index_id          :bigint           not null
#
# Indexes
#
#  index_namespace_index_cooldowns_on_index_id  (index_id)
#
# Foreign Keys
#
#  fk_rails_...  (index_id => namespace_indexes.id)
#
