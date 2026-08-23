require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "index without query" do
    get search_url, headers: peak_admin_authorization
    assert_response :success
    assert_results 0
  end

  test "index with namespace matching query" do
    get search_url(q: "gem"), headers: peak_admin_authorization
    assert_response :success
    assert_results 2 do
      assert_dom "a", "@gemcoop"
      assert_dom "a", "@gemcoop/peak"
      assert_dom "p mark", "gem"
    end
  end

  test "index with gem matching query" do
    get search_url(q: "oak"), headers: peak_admin_authorization
    assert_response :success
    assert_results 2 do
      assert_dom "a", "@public/oaken"
      assert_dom "a", "@gemcoop/oaken"
    end
  end

  test "index with gem summary query" do
    get search_url(q: "aims"), headers: peak_admin_authorization
    assert_response :success
    assert_results 1 do
      assert_dom "a", "@gemcoop/oaken"
    end
  end

  test "index with gem summary query partial match on two terms" do
    get search_url(q: "aim fix"), headers: peak_admin_authorization
    assert_response :success
    assert_results 1 do
      assert_dom "a", "@gemcoop/oaken"
    end
  end

  private
    def assert_results(count, &)
      # puts dom("#search-listings article")
      assert_dom("#search-listings article", count:, &)
    end
end
