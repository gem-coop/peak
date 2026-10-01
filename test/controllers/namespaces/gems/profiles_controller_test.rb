require "test_helper"

class Namespaces::Gems::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "get show" do
    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_dom "section li", /#{gems.peak.versions.first.ref}/
  end

  test "get show with no versions" do
    gems.peak.versions.delete_all

    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_dom "header span", /no versions yet/
  end
end
