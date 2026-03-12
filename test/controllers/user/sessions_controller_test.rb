require "test_helper"

class User::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "show creates session from magic link" do
    assert_increments User::Session do
      get user_session_url(users.plain.magic_link.signed_id)
    end
    assert_redirected_to root_url
  end

  test "show with expired magic link" do
    signed_id = users.plain.magic_link.signed_id
    travel 15.minutes + 1.second

    get user_session_url(signed_id)
    assert_redirected_to sign_in_url
  end

  test "destroy signs out" do
    sign_in_as users.plain

    assert_difference -> { User::Session.count }, -1 do
      delete sign_out_url
    end
    assert_redirected_to root_url
  end
end
