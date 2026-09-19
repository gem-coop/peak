require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup { cache_store.clear }

  test "rate_limit" do
    rate_limiting.increment by: 40
    get search_url
    assert_response :too_many_requests
  end

  test "index without query" do
    get search_url
    assert_response :success
    assert_results 0
  end

  test "index with namespace matching query" do
    get search_url(q: "gem")
    assert_response :success
    assert_results 3 do
      assert_dom "a", "@gemcoop"
      assert_dom "a", "@gemcoop/peak"
      assert_dom "p mark", "gem"
    end
  end

  test "index with gem matching query" do
    get search_url(q: "oak")
    assert_response :success
    assert_results 2 do
      assert_dom "a", "@rubygems/oaken"
      assert_dom "a", "@gemcoop/oaken"
    end
  end

  test "index with gem summary query" do
    get search_url(q: "aims")
    assert_response :success
    assert_results 1 do
      assert_dom "a", "@gemcoop/oaken"
    end
  end

  test "index with gem summary query partial match on two terms" do
    get search_url(q: "aim fix")
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
