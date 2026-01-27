require "test_helper"

class Namespaces::GemsControllerTest < ActionDispatch::IntegrationTest
  test "show with missing gem" do
    head namespaces_gems_url(namespace: namespaces.gemcoop, id: "nonexistent-1.0.0.gem")
    assert_response :not_found
  end

  test "get show with redirect" do
    version = versions.by gems.oaken, ref: "0.9.1"

    head namespaces_gems_url(namespace: namespaces.gemcoop, id: version)
    assert_redirected_to "https://gem.coop/gems/oaken-0.9.1.gem"
  end

  test "get show with upload" do
    get namespaces_gems_url(namespace: namespaces.gemcoop, id: gems.peak.versions.first)
    assert_response :success

    upload = Peak::Gem::Upload.read(StringIO.new(response.body))
    assert upload.spec
  ensure
    upload.unlink
  end

  test "push" do
    sign_in users.plain

    package = file_fixture "peak/peak-0.2.0.gem"

    assert_increments gems.peak.versions do
      post gem_push_url, env: { "RAW_POST_DATA" => package.binread }
    end
    assert_response :success
    refute_empty response.body, "bundler throws an exception in case there's no text in the response"
    assert_match "peak-0.2.0.gem uploaded 🎉", response.body

    version = namespace.versions.last
    assert_equal "peak-0.2.0", version.name
    assert_equal "bcd14ad61176553b5202726ffba2892fe3bd5b3b32e18461fd36335f71c64d72", version.checksum
    assert_equal ">= 4.0", version.ruby
    assert_equal ">= 2.7", version.rubygems
    assert_equal ["peak"], version.executables
    assert_equal ["MIT"], version.licenses
    assert_equal Date.today, version.published_at.to_date
    assert version.package.attached?
    assert_equal package.binread, version.package.download
  end
end
