require "test_helper"

class CooldownVersionBackfillPublishedAtJobTest < ActiveJob::TestCase
  test "backfills dates until reaching 48 hours ago" do
    travel_to Time.parse("2025-10-30") do
      stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").open)
      stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").open)
      Rails.cache.clear
      CooldownVersion.import
      perform_enqueued_jobs

      stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").to_return(
        body: file_fixture("rake.json").open, headers: {"content-type": "application/json"})
      CooldownVersionBackfillPublishedAtJob.perform_now

      published_at = JSON.parse(file_fixture("rake.json").read).dig(0, "created_at")
      assert_equal Time.parse(published_at), CooldownVersion.find_by(version: "13.3.1").published_at
    end
  end
end
