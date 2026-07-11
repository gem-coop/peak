require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  class TestController < ApplicationController
    require_authentication
    allow_unauthenticated_access only: :open

    def open = render plain: "open"
    def secret = render plain: "secret"
  end

  with_routing do |routes|
    routes.draw do
      controller "authentication_test/test" do
        get :open
        get :secret
        get :dashboard, action: :secret # sign_ins#update redirects here
      end

      resources :sign_in, controller: "user/sign_ins", only: %i[new show], param: :token do
        patch :update, on: :collection
      end

      post "sign_in/test", to: "test/sign_in#create", as: :test_sign_in
    end
  end

  setup { host! "https://example.com" }

  test "require_authentication redirects an unauthenticated request to sign in" do
    get secret_url
    assert_redirected_to new_sign_in_url(redirect_url: secret_url)
  end

  test "require_authentication allows a request carrying a live session" do
    sign_in_as users.plain
    get secret_url

    assert_response :success
    assert_equal "secret", response.body
  end

  test "allow_unauthenticated_access lets an unauthenticated request through" do
    get open_url

    assert_response :success
    assert_equal "open", response.body
  end
end
