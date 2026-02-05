require "test_helper"

class User::KeysControllerTest < ActionDispatch::IntegrationTest
  setup { @token = users.plain.push_key_install_token }

  test "show with valid token can show push key" do
    get user_key_url(id: @token)
    assert_response :success
    assert_equal users.plain.push_key, response.body
  end

  test "show with expired token cannot show push key" do
    travel 9.hours

    get user_key_url(id: @token)
    assert_response :unauthorized
    assert_empty response.body
  end
end
