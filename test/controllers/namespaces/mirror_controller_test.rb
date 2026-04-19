require "test_helper"

class Namespaces::MirrorControllerTest < ActionDispatch::IntegrationTest
  test "versions" do
    get "/versions"
    assert_response 200
  end

  test "info" do
    get "/info/oaken"
    assert_response 200
  end

  test "gems" do
    get "/gems/oaken-1.0.0.gem"
    assert_response 302
    assert_redirected_to "https://gem.coop/gems/oaken-1.0.0.gem"
  end
end
