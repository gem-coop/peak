require "test_helper"

class Namespace::Index::CooldownTest < ActiveSupport::TestCase
  test "includes envelope published before threshold" do
    assert_match cooldown.versions.latest_for(:oaken).envelope, cooldown.contents
  end

  test "excludes envelope not yet within threshold" do
    cooldown.versions.update_all published_at: cooldown.interval.ago + 1.second
    assert_empty cooldown.versions
  end

  test "refresh doesn't needlessly bust cache_version" do
    cooldown.versions.update_all published_at: cooldown.refreshed_at - 1.second
    assert_no_changes(-> { cooldown.cache_version }) { cooldown.refresh }
  end

  private def cooldown = cooldowns.gemcoop
end
