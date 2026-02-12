require "test_helper"

class Namespaces::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "get show" do
    get namespace_url(namespaces.gemcoop)
    assert_response :success
    assert_dom "article", Regexp.new(gems.oaken.name)
  end

  test "get show with no gems" do
    get namespace_url(namespaces.blank)
    assert_response :success

    namespaces.blank.external_index.gems.create name: "first"

    get namespace_url(namespaces.blank)
    assert_response :success
  end
end
