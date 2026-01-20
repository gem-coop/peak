require "test_helper"

class Namespaces::GemsControllerTest < ActionDispatch::IntegrationTest
  def namespace = namespaces.gemcoop

  test "show with missing gem" do
    head namespaces_gems_url(namespace:, id: "nonexistent-1.0.0.gem")
    assert_response :not_found
  end

  test "get show" do
    version = versions.by gems.oaken, ref: "0.9.1"

    head namespaces_gems_url(namespace:, id: version)
    assert_redirected_to "https://gem.coop/gems/oaken-0.9.1.gem"
  end
end
