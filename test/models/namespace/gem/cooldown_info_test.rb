require "test_helper"

class Namespace::Gem::CooldownInfoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: namespace_gem_cooldown_infos
#
#  id          :bigint           not null, primary key
#  checksum    :string           default(""), not null
#  contents    :text             default(""), not null
#  envelope    :string           default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  cooldown_id :bigint           not null
#  gem_id      :bigint           not null
#
# Indexes
#
#  index_namespace_gem_cooldown_infos_on_cooldown_id  (cooldown_id)
#  index_namespace_gem_cooldown_infos_on_gem_id       (gem_id)
#
# Foreign Keys
#
#  fk_rails_...  (cooldown_id => namespace_index_cooldowns.id)
#  fk_rails_...  (gem_id => namespace_gems.id)
#
