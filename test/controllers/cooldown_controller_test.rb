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

  test "bundle install endpoints work across hourly updates" do
    # import up to rake 13.2.1
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").read.lines[0...-3].join)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").read.lines[0...-2].join)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    assert_equal "13.2.1", CooldownVersion.last&.version

    get "/cooldown/versions"
    assert_response :success
    assert_includes response.body, "13.2.1"
    assert_not_includes response.body, "13.3.0"

    get "/cooldown/info/rake"
    assert_response :success
    assert_includes response.body, "13.2.1"
    assert_not_includes response.body, "13.3.0"

    # we don't cooldown the .gem files, at least so far
    get "/cooldown/gems/rake-13.2.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.2.0.gem"
    get "/cooldown/gems/rake-13.3.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.3.0.gem"

    # import everything, including rake 13.3.0
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").open)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    assert_equal "13.3.0", CooldownVersion.cooled.last.version

    get "/cooldown/versions"
    assert_response :success
    assert_includes response.body, "13.2.1"
    assert_includes response.body, "13.3.0"

    get "/cooldown/info/rake"
    assert_response :success
    assert_includes response.body, "13.2.1"
    assert_includes response.body, "13.3.0"

    get "/cooldown/gems/rake-13.2.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.2.0.gem"
    get "/cooldown/gems/rake-13.3.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.3.0.gem"
  end

  test "cooldown responses support range headers" do
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").open)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs
    assert_equal "13.3.0", CooldownVersion.last&.version

    get "/cooldown/versions", headers: {Range: "bytes=0-100"}
    assert_response :partial_content
    assert_includes response.body.byteslice(0..100), "0.4.11"
    assert_not_includes response.body.byteslice(0..100), "13.3.0"

    get "/cooldown/info/rake", headers: {Range: "bytes=0-100"}
    assert_response :partial_content
    assert_includes response.body, "0.5.0"
    assert_not_includes response.body, "13.3.0"
  end
end
