require "test_helper"

class Namespace::Mirror::SyncFanoutJobTest < ActiveJob::TestCase
  test "syncs all the mirrors" do
    # seeds include namespaces.rubygems.mirror, enabled
    namespaces.gemcoop.create_mirror!(url: "https://gem.coop", enabled: true)

    assert_equal Namespace::Mirror.pluck(:enabled), [false, true]
    assert_no_enqueued_jobs
    Namespace::Mirror::SyncFanoutJob.new.perform

    # enqueue the seed mirror but not the disabled mirror we just created
    assert_enqueued_jobs 1
  end
end
