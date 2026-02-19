require "test_helper"

class Namespaces::IndexControllerTest < ActionDispatch::IntegrationTest
  def namespace = namespaces.gemcoop

  test "get index" do
    get namespace_versions_url(namespace:)
    assert_response :success
    assert_text /^oaken/
  end

  test "get show missing" do
    get namespace_info_url(namespace:, id: gems.activerecord)
    assert_response :not_found
  end

  test "get show" do
    get namespace_info_url(namespace:, id: gems.oaken)
    assert_response :success
    assert_equal gems.oaken_lines, response.body.split("\n")
  end

  test "get show with dependencies" do
    get namespace_info_url(namespace:, id: gems.peak)
    assert_response :success
    assert_text "0.1.0 oaken:>= 0.9&~> 1.0.1"
  end

  test "get /dev index" do
    get namespace_versions_url(namespace:, index: "dev")
    assert_response :success
  end

  test "get /private index" do
    get namespace_versions_url(namespace:, index: "private")
    assert_response :not_found
  end

  private def assert_text(text) = assert_match(text, response.body)
end
