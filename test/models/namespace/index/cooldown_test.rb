require "test_helper"

class Namespace::Index::CooldownTest < ActiveSupport::TestCase
  test "includes envelope published before threshold" do
    assert_match cooldown.versions.by_gem(:oaken).latest.envelope, cooldown.contents
  end

  test "excludes envelope not yet within threshold" do
    cooldown.versions.update_all published_at: cooldown.published_threshold + 1.second
    assert_empty cooldown.versions
  end

  test "new_versions_since_last_refresh excludes versions already included" do
    cooldown.versions.update_all published_at: cooldown.updated_at - 1.second
    assert_empty cooldown.new_versions_since_last_refresh
  end

  test "refresh doesn't needlessly bust cache_version" do
    cooldown.versions.update_all published_at: cooldown.updated_at - 1.second
    assert_no_changes(-> { cooldown.cache_version }) { cooldown.refresh }
  end

  test "refresh pulls in version published after last refresh within threshold" do
    cooldown.update! interval: 1.minute, updated_at: 10.minutes.ago
    cooldown.versions.update_all published_at: cooldown.updated_at - 1.second

    version = cooldown.versions.by_gem(:oaken).latest
    version.update! published_at: cooldown.updated_at + 1.second
    assert_includes cooldown.new_versions_since_last_refresh, version

    version.update! published_at: Time.current
    refute_includes cooldown.new_versions_since_last_refresh, version
  end

  private def cooldown = cooldowns.gemcoop_cooldown
end
