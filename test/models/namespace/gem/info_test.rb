require "test_helper"

class Namespace::Gem::InfoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: namespace_gem_infos
#
#  id         :bigint           not null, primary key
#  checksum   :string           default(""), not null
#  contents   :text             default(""), not null
#  envelope   :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  gem_id     :bigint           not null
#
# Indexes
#
#  index_namespace_gem_infos_on_gem_id  (gem_id)
#
