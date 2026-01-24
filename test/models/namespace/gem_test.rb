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
    versions = gem.versions
    assert_nil gem.trim_versions_published_at
    assert_equal versions, versions.trimmed

    gem.trim_versions_published_at = 1.day.from_now
    assert_empty versions.trimmed
  end
end
