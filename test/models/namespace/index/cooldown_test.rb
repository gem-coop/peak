require "test_helper"

class Namespace::Index::CooldownTest < ActiveSupport::TestCase
  test "includes envelope published before threshold" do
    assert_match cooldown.versions.latest_for(:oaken).envelope, cooldown.contents
  end

  test "excludes envelope not yet within threshold" do
    cooldown.versions.update_all published_at: cooldown.published_threshold + 1.second
    assert_empty cooldown.versions
  end

  test "versions.refreshed excludes versions already in contents" do
    cooldown.versions.update_all published_at: cooldown.refreshed_at - 1.second
    assert_empty cooldown.versions.refreshed
  end

  test "refresh doesn't needlessly bust cache_version" do
    cooldown.versions.update_all published_at: cooldown.refreshed_at - 1.second
    assert_no_changes(-> { cooldown.cache_version }) { cooldown.refresh }
  end

  test "refresh pulls in version published after last refresh within threshold" do
    cooldown.update! interval: 1.minute, refreshed_at: 10.minutes.ago
    cooldown.versions.update_all published_at: cooldown.refreshed_at - 1.second

    version = cooldown.versions.latest_for(:oaken)
    version.update! published_at: cooldown.refreshed_at + 1.second
    assert_includes cooldown.versions.refreshed, version

    version.update! published_at: Time.current
    refute_includes cooldown.versions.refreshed, version
  end

  private def cooldown = cooldowns.gemcoop
end
