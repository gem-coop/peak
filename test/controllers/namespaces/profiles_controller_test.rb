require "test_helper"

class Namespaces::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "get show" do
    get namespace_url(namespaces.gemcoop)
    assert_response :success

    assert_dom "article", /^oaken/ do
      not_latest, latest = gems.oaken.versions.last(2)

      assert_dom "ul li", /^#{latest.ref}/
      refute_dom "ul li", /^#{not_latest.ref}/
    end
  end

  test "get show with no gems" do
    get namespace_url(namespaces.blank)
    assert_response :success

    namespaces.blank.default_index.gems.create name: "unversioned"

    get namespace_url(namespaces.blank)
    assert_response :success
    assert_not_dom "article", "unversioned"
  end
end
