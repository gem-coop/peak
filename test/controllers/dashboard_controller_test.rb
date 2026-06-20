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

  test "owner sees a trusted publishers link for an owned namespace" do
    sign_in_as users.owner
    get dashboard_url
    assert_response :success
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name)
  end

  test "non-owner sees no trusted publishers link" do
    sign_in_as users.plain
    get dashboard_url
    assert_response :success
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name), count: 0
  end
end
