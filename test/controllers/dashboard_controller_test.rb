require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "show requires authentication" do
    get dashboard_url
    assert_redirected_to new_sign_in_url(redirect_url: dashboard_url)
  end

  test "show when authenticated" do
    sign_in_as users.plain

    get dashboard_url
    assert_response :success
    assert_match users.plain.name, response.body
  end
end
