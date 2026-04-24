require "test_helper"

class Namespace::GemTest < ActiveSupport::TestCase
  test "referrants" do
    version = versions.by gems.activesupport, ref: "8.1.1"
    referrant = version.referrants.sole

    assert referrant.eq?
    assert_equal "8.1.1", referrant.ref
    assert_includes gems.activesupport.referrants, referrant
  end

  test "versions.trimmed" do
    gem = gems.oaken
    versions = gem.versions.published_order
    assert_nil gem.trim_versions_published_at
    assert_equal versions, versions.trimmed

    gem.trim_versions_published_at = 1.day.from_now
    assert_empty versions.trimmed
  end
end

# == Schema Information
#
# Table name: namespace_gems
#
#  id                         :bigint           not null, primary key
#  name                       :string           not null
#  trim_versions_published_at :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  index_id                   :bigint           not null
#  namespace_id               :bigint           not null
#
# Indexes
#
#  index_namepace_gems_uniqueness        (index_id,name) UNIQUE
#  index_namespace_gems_on_index_id      (index_id)
#  index_namespace_gems_on_namespace_id  (namespace_id)
#
