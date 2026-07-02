require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "index without query" do
    get search_url, headers: peak_admin_authorization
    assert_response :success
  end

  test "index with namespace matching query" do
    get search_url(q: "oak"), headers: peak_admin_authorization
    assert_response :success
    assert_dom "#search-listings article", count: 2
  end

  test "index with gem matching query" do
    get search_url(q: "oak"), headers: peak_admin_authorization
    assert_response :success
    assert_dom "#search-listings article", count: 2
  end

  test "index with gem summary query" do
    get search_url(q: "aims"), headers: peak_admin_authorization
    assert_response :success
    assert_dom "#search-listings article", count: 1
  end
end
