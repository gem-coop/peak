require "test_helper"

# Exercises the Authentication concern directly through inline controllers so the
# class-level macros (require_authentication / allow_unauthenticated_access) are
# tested in isolation, independent of any real controller's own behavior.
class AuthenticationTest < ActionDispatch::IntegrationTest
  class NeedsAuthController < ApplicationController
    require_authentication
    def show = render plain: "secret"
  end

  class SkipsAuthController < ApplicationController
    require_authentication
    allow_unauthenticated_access only: :show
    def show = render plain: "open"
  end

  setup do
    host! "example.com" # match config/initializers/hosts.rb so the sign-in redirect is same-host

    @draw = ->(set) do
      set.draw do
        get "/needs_auth", to: "authentication_test/needs_auth#show"
        get "/skips_auth", to: "authentication_test/skips_auth#show"
        get "/dashboard",  to: "authentication_test/needs_auth#show", as: :dashboard # sign_ins#show redirects here
        resources :sign_in, controller: "user/sign_ins", only: %i[new show] # sign_in_url / new_sign_in_url
      end
    end
  end

  test "require_authentication redirects an unauthenticated request to sign in" do
    with_routing do |set|
      @draw.call set
      get "/needs_auth"

      assert_response :redirect
      assert_match %r{/sign_in/new}, response.location
      assert_match %r{redirect_url=}, response.location
    end
  end

  test "require_authentication allows a request carrying a live session" do
    with_routing do |set|
      @draw.call set
      sign_in_as users.plain
      get "/needs_auth"

      assert_response :success
      assert_equal "secret", response.body
    end
  end

  test "allow_unauthenticated_access lets an unauthenticated request through" do
    with_routing do |set|
      @draw.call set
      get "/skips_auth"

      assert_response :success
      assert_equal "open", response.body
    end
  end
end
