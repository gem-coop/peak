require "test_helper"

class Namespace::Gem::Version::ReferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: namespace_gem_version_references
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  operator   :string           not null
#  ref        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_namespace_gem_version_references_on_name  (name)
#  namespace_gem_version_references_uniqueness     (name,operator,ref) UNIQUE
#
