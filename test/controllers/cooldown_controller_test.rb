require "test_helper"

class CooldownControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").to_return(
      body: file_fixture("rake.json").open, headers: {"content-type": "application/json"})
  end

  test "errors without gem dates" do
    stub_request(:get, "https://rubygems.org/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://rubygems.org/info/rake").to_return(body: file_fixture("info/rake").open)

    get "/cooldown/versions"
    assert_response :error

    get "/cooldown/info/rake"
    assert_response :error

    get "/cooldown/gems/rake-13.3.1.gem"
    assert_response :error
  end

  test "bundle install endpoints work across hourly updates" do
    travel_to Time.utc(2026, 4, 19, 11, 47, 00)

    # import up to rake 13.2.1
    stub_request(:get, "https://rubygems.org/versions").to_return(body: file_fixture("versions").read.lines[0...-4].join)
    stub_request(:get, "https://rubygems.org/info/rake").to_return(body: file_fixture("info/rake").read.lines[0...-2].join)
    perform_import
    assert_equal "13.2.1", Namespace::Gem.find_by(name: "rake").versions.last&.ref

    get "/cooldown/versions"
    assert_response :success
    assert_match %r{13\.2\.1}, response.body
    assert_not_includes response.body, "13.3.0"

    get "/cooldown/info/rake"
    assert_response :success
    assert_match %r{13\.2\.1}, response.body
    assert_not_includes response.body, "13.3.0"

    # we don't cooldown the .gem files, at least so far
    get "/cooldown/gems/rake-13.2.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.2.0.gem"
    get "/cooldown/gems/rake-13.3.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.3.0.gem"

    # import everything, including rake 13.3.0
    stub_request(:get, "https://rubygems.org/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://rubygems.org/info/rake").to_return(body: file_fixture("info/rake").open)
    perform_import
    assert_equal "13.3.1", Namespace.named("@public").external_index.cooldown(days: 2).gems.last.versions.last.ref

    get "/cooldown/versions"
    assert_response :success
    assert_match %r{13\.2\.1}, response.body
    assert_match %r{13\.3\.0}, response.body

    get "/cooldown/info/rake"
    assert_response :success
    assert_match %r{13\.2\.1}, response.body
    assert_match %r{13\.3\.0}, response.body

    get "/cooldown/gems/rake-13.2.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.2.0.gem"
    get "/cooldown/gems/rake-13.3.0.gem"
    assert_redirected_to "https://gem.coop/gems/rake-13.3.0.gem"
  end

  test "cooldown responses support range headers" do
    travel_to Time.utc(2026, 4, 19, 11, 47, 00)
    stub_request(:get, "https://rubygems.org/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://rubygems.org/info/rake").to_return(body: file_fixture("info/rake").open)
    perform_import
    assert_equal "13.3.1", Namespace.named("@public").external_index.cooldown(days: 2).gems.last.versions.last.ref

    get "/cooldown/versions"
    full_size = response.body.size
    assert_includes response.body, "13.3.1"

    get "/cooldown/versions", headers: {Range: "bytes=0-99"}
    assert_response :partial_content
    assert_equal 100, response.body.size
    assert_equal %("0453b00398fdd27efc819092d949adbf"), response.headers["etag"]
    assert_equal %(sha256="fb1a511c3271cbb28d62d2d2906384ecf16e6bd3ec2e441c4c337354f8b4a97c"), response.headers["digest"]

    get "/cooldown/versions", headers: {Range: "bytes=100-"}
    assert_response :partial_content
    assert_equal full_size - 100, response.body.size
    assert_includes response.body, "0.4.11"
    assert_not_includes response.body, "13.3.0"

    get "/cooldown/versions", headers: {Range: "bytes=-200"}
    assert_response :partial_content
    assert_equal 200, response.body.length
    assert_includes response.body, "0.4.11"
    assert_not_includes response.body, "13.3.0"

    get "/cooldown/info/rake", headers: {Range: "bytes=0-99"}
    assert_response :partial_content
    assert_equal 100, response.body.length
    assert_includes response.body, "0.4.11"
    assert_not_includes response.body, "0.5.0"
  end

  private
    def perform_import
      Rails.cache.clear
      Namespace::Index::Mirror::Upstream.memory_store.clear
      mirror = Namespace::Index::Mirror.last
      cooldown = mirror.index.cooldowns.find_or_create_by!(days_delayed: 2)
      Sidekiq::Queue.stub :new, [] do
        mirror.import
      end
      cooldown.rebuild_infos(period: 1_000_000.days)
      mirror.index.compact
      perform_enqueued_jobs
    end
end
