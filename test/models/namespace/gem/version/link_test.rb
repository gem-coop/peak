require "test_helper"

class Namespace::Gem::Version::LinkTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: namespace_gem_version_links
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  value      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  namespace_gem_version_links_uniqueness  (key,value) UNIQUE
#
