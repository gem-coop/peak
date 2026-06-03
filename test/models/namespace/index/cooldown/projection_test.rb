require "test_helper"

class Namespace::Index::Cooldown::ProjectionTest < ActiveSupport::TestCase
  setup :freeze_time
  setup do
    @version = cooldown.versions.first.tap { _1.update! published_at: 1.second.from_now }
    @projection = cooldown.project @version
  end

  test "due condition variable around append_at future then past" do
    assert_empty cooldown.projections.due
    refute_includes Namespace::Index::Cooldown.refresh_due, cooldown

    travel_to @projection.append_at

    assert_includes cooldown.projections.due, @projection
    assert_includes Namespace::Index::Cooldown.refresh_due, cooldown
  end

  test "interval alignment" do
    assert_equal cooldown.interval.from_now + 1.second, @projection.append_at

    assert_changes -> { @projection.reload.append_at }, to: (1.minute + 1.second).from_now do
      cooldown.update! interval: 1.minute
    end
  end

  test "refresh pulls in due projection version" do
    travel_to @projection.append_at

    assert_changes -> { cooldown.manifest.contents.lines.last } do
      assert_decrements cooldown.projections do
        cooldown.refresh
      end
    end
  end

  private def cooldown = cooldowns.gemcoop
end
