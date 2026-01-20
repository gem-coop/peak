require "test_helper"

class Namespaces::GemsControllerTest < ActionDispatch::IntegrationTest
  test "show with missing gem" do
    head namespaces_gems_url(namespace: namespaces.gemcoop, id: "nonexistent-1.0.0.gem")
    assert_response :not_found
  end

  test "get show" do
    version = versions.by gems.oaken, ref: "0.9.1"

    head namespaces_gems_url(namespace: namespaces.gemcoop, id: version)
    assert_redirected_to "https://gem.coop/gems/oaken-0.9.1.gem"
  end

  test "push" do
    sign_in users.plain

    package = file_fixture "peak-0.1.0.gem"

    assert_increments namespace.gems.where(name: "peak") do
      post gem_push_url, env: { "RAW_POST_DATA" => package.binread }
    end
    assert_response :success

    gem = namespace.gems.last
    assert_equal "peak", gem.name
    assert_equal "0.1.0", gem.versions.sole.ref
    assert gem.versions.sole.package.attached?
    assert_equal package.binread, gem.versions.sole.package.download
  end
end
