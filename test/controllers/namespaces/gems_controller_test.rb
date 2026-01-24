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

    package = file_fixture "peak-0.2.0.gem"

    assert_increments gems.peak.versions do
      post gem_push_url, env: { "RAW_POST_DATA" => package.binread }
    end
    assert_response :success
    refute_empty response.body, "bundler throws an exception in case there's no text in the response"
    assert_match "peak-0.2.0.gem uploaded 🎉", response.body

    version = namespace.versions.last
    assert_equal "peak-0.2.0", version.name
    assert_equal "32d09926fd46add289c0470cf560819b1e8f581c5ca3f3219e0895a222645290", version.checksum
    assert version.package.attached?
    assert_equal package.binread, version.package.download
  end
end
