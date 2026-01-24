require "test_helper"

class Namespaces::IndexControllerTest < ActionDispatch::IntegrationTest
  def namespace = namespaces.gemcoop

  test "get index" do
    get namespaces_versions_url(namespace:)
    assert_response :success
    assert_text /^oaken/
  end

  test "get show missing" do
    get namespaces_info_url(namespace:, id: gems.activerecord)
    assert_response :not_found
  end

  test "get show" do
    get namespaces_info_url(namespace:, id: gems.oaken)
    assert_response :success
    assert_equal gems.oaken_lines, response.body.split("\n")
  end

  test "get show with dependencies" do
    get namespaces_info_url(namespace: namespaces.public, id: gems.activerecord)
    assert_response :success
    assert_text "8.1.1 activemodel:= 8.1.1,activesupport:= 8.1.1,timeout:>= 0|published_at:"

    get namespaces_info_url(namespace: namespaces.public, id: gems.activesupport)
    assert_response :success
    assert_text "8.1.1 base64:>= 0,bigdecimal:>= 0,concurrent-ruby:>= 1.3.1&~> 1.0,connection_pool:>= 2.2.5,drb:>= 0,i18n:< 2&>= 1.6,json:>= 0,logger:>= 0|published_at:"
  end

  private def assert_text(text) = assert_match(text, response.body)
end
