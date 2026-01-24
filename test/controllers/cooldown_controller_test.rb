require "test_helper"

class CooldownControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").to_return(
      body: file_fixture("rake.json").open, headers: {"content-type": "application/json"})
  end

  test "errors without gem dates" do
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").open)

    get "/cooldown/versions"
    assert_response :error

    get "/cooldown/info/rake"
    assert_response :error

    get "/cooldown/gems/rake-13.3.1.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.3.1.gem"
  end

  test "bundle install endpoints work" do
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").read.lines[0...-3].join)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").read.lines[0...-3].join)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    CooldownVersion.update_all(published_at: 50.hours.ago)
    CooldownVersion.find_by(version: "13.2.0")&.update(published_at: 49.hours.ago)
    assert_equal "13.2.0", CooldownVersion.last&.version

    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").open)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    assert_equal "13.3.1", CooldownVersion.last.version

    cv = CooldownVersion.where("published_at < ?", 48.hours.ago).order(:published_at).last
    assert_equal "13.2.0", cv.version

    get "/cooldown/versions"
    assert_response :success
    assert_equal file_fixture("versions").read.lines[0..1].join, response.body
    assert_includes response.body, "13.2.0"
    assert_not_includes response.body, "13.3.1"

    get "/cooldown/info/rake"
    assert_response :success
    assert_includes response.body, "13.2.0"
    assert_not_includes response.body, "13.3.1"

    get "/cooldown/gems/rake-13.2.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.2.0.gem"
    get "/cooldown/gems/rake-13.3.1.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.3.1.gem"
  end
end
