require "test_helper"

class CooldownVersionBackfillCreatedAtJobTest < ActiveJob::TestCase
  test "backfills dates until reaching 48 hours ago" do
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").open)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs
    CooldownVersion.update_all(created_at: Time.now)

    stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").to_return(
      body: file_fixture("rake.json").open, headers: {"content-type": "application/json"})
    CooldownVersionBackfillCreatedAtJob.perform_now

    assert_equal Time.parse("2025-10-29 05:41:55.799000000 +0000"), CooldownVersion.find_by(version: "13.3.1").created_at
  end
end
