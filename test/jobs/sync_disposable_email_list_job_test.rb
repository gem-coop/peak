require "test_helper"

class SyncDisposableEmailListJobTest < ActiveJob::TestCase
  test "retries when the list can't be fetched" do
    failing = stub_request(:get, Peak::DisposableEmailList::URL).to_timeout
    SyncDisposableEmailListJob.perform_later

    assert_raises HTTPX::TimeoutError do
      perform_enqueued_jobs while enqueued_jobs.any?
    end

    assert_requested failing, times: 5
  end

  test "gives up on a list that fails our sanity bounds" do
    poisoned = stub_request(:get, Peak::DisposableEmailList::URL).to_return(body: "gmail.com\nmailinator.com\n")

    Peak::DisposableEmailList.with(expected_size: 2..10) do
      SyncDisposableEmailListJob.perform_later
      perform_enqueued_jobs
    end

    assert_requested poisoned, times: 1
    assert_empty Peak::BlockedDomain.disposable_email_list
  end
end
