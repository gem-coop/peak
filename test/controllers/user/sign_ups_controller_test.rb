require "test_helper"

class User::SignUpsControllerTest < ActionDispatch::IntegrationTest
  test "get new" do
    get user_sign_ups_url
    assert_response :success
  end

  test "post create success" do
    assert_increments User, Namespace, Namespace::Access do
      post user_sign_ups_url, params: sign_up_params
    end
    assert_response :success

    assert_equal "Someone", User.last.name
    assert_equal "someone@example.com", User.last.email_address
    assert_equal "@someone", Namespace.last.name
    assert_equal User.last, Namespace.last.accesses.owner.user
  end

  test "post create with taken email address" do
    refute_increments User, Namespace, Namespace::Access do
      post user_sign_ups_url, params: sign_up_params(email_address: users.owner.email_address)
    end
    assert_response :unprocessable_entity
  end

  test "post create with taken namespace name" do
    refute_increments User, Namespace, Namespace::Access do
      post user_sign_ups_url, params: sign_up_params(namespace_name: namespaces.gemcoop.name)
    end
    assert_response :unprocessable_entity
  end

  private
    def sign_up_params(name: "Someone", email_address: "someone@example.com", namespace_name: "@someone")
      { user_sign_up: { name:, email_address:, namespace_name: } }
    end
end
