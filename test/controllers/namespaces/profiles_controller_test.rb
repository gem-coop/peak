require "test_helper"

class Namespaces::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "get show" do
    get namespaces_profile_url(namespace: namespaces.gemcoop)
    assert_response :success
    assert_dom "article", Regexp.new(gems.oaken.name)
  end
end
