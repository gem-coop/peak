require "test_helper"

class User::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "destroy signs out when signed in" do
    sign_in_as users.plain

    assert_decrements(User::Session) { delete sign_out_url }
    assert_redirected_to root_url
  end

  test "destroy signs out even when not signed in" do
    delete sign_out_url
    assert_redirected_to root_url
  end
end
