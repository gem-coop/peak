require "test_helper"

class Namespace::Gem::VersionTest < ActiveSupport::TestCase
  test "versions" do
    refs = gems.oaken.versions.pluck :ref
    assert_includes refs, "0.9.1"
    assert_includes refs, "1.0.0"
  end

  test "checksum parsing" do
    version = versions.by gems.actionview, ref: "8.1.0"
    assert_equal "b7e8770a5aacd389a3c04916d29609a53459447fcbf747150437136d44c1d1f3", version.checksum
  end
end

# == Schema Information
#
# Table name: namespace_gem_versions
#
#  id             :bigint           not null, primary key
#  checksum       :string
#  executables    :json             not null
#  has_extensions :boolean
#  licenses       :json             not null
#  published_at   :datetime         not null
#  ref            :string           not null
#  ruby           :string
#  rubygems       :string
#  summary        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  created_by_id  :bigint           not null
#  gem_id         :bigint           not null
#  platform_id    :bigint           not null
#
# Indexes
#
#  index_namepace_gem_versions_uniqueness         (gem_id,ref) UNIQUE
#  index_namespace_gem_versions_on_created_by_id  (created_by_id)
#  index_namespace_gem_versions_on_gem_id         (gem_id)
#  index_namespace_gem_versions_on_platform_id    (platform_id)
#
