require "test_helper"

class Namespaces::Gems::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_dom "section li", /#{gems.peak.versions.first.ref}/
  end
end
