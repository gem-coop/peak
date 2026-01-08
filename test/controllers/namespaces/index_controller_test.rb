require "test_helper"

class Namespaces::IndexControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get namespaces_index_index_url
    assert_response :success
  end

  test "should get show" do
    get namespaces_index_show_url
    assert_response :success
  end
end
