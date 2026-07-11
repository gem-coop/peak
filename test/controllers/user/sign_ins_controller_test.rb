require "test_helper"

class User::SignInsControllerTest < ActionDispatch::IntegrationTest
  setup { User::SignInsController.cache_store.clear }

  test "get new" do
    get new_sign_in_url
    assert_response :success
  end

  test "post create" do
    post sign_in_index_url, params: { email_address: users.plain.email_address }
    assert_response :success

    perform_enqueued_jobs
    assert_emails 1
    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal [users.plain.email_address], mail.to
      assert_match "Sign in", mail.subject
      assert_match "sign_in/", mail.text_part.body.to_s
    end
  end

  test "create doesn't let slip if the user doesn't exist" do
    post sign_in_index_url, params: { email_address: "nonexistent@example.com" }
    assert_response :success
    assert_match "Check your email", response.body

    perform_enqueued_jobs
    assert_emails 0
  end

  test "create rate limit" do
    4.times do
      post sign_in_index_url, params: { email_address: users.plain.email_address }
    end

    assert_response :too_many_requests
  end

  test "show redirects to a token-less confirmation page" do
    token = users.plain.magic_link.token

    refute_increments(User::Session) { get sign_in_url(token) }
    assert_redirected_to edit_sign_in_index_url
    assert_equal "strict-origin", response.headers["referrer-policy"]

    follow_redirect!
    assert_response :success
    refute_match token, response.body
    assert_dom "form input[name=confirmation_nonce]"
  end

  test "show rejects a used magic link" do
    token = users.plain.magic_link.token
    sign_in_as users.plain

    refute_increments(User::Session) { get sign_in_url(token) }
    assert_redirected_to new_sign_in_url
  end

  test "update creates session from pending magic link" do
    with_confirmation_nonce do |nonce|
      get sign_in_url(users.plain.magic_link.token)

      assert_increments(User::Session) { patch sign_in_index_url, params: { confirmation_nonce: nonce } }
      assert_redirected_to dashboard_url
    end
  end

  test "update creates session from pending magic link — with redirect_url" do
    get new_sign_in_url(redirect_url: new_user_push_key_url)

    with_confirmation_nonce do |nonce|
      get sign_in_url(users.plain.magic_link.token)

      assert_increments(User::Session) { patch sign_in_index_url, params: { confirmation_nonce: nonce } }
      assert_redirected_to new_user_push_key_url
    end
  end

  test "update requires a pending magic link" do
    refute_increments User::Session do
      patch sign_in_index_url, params: { token: users.plain.magic_link.token }
    end
    assert_redirected_to new_sign_in_url
  end

  test "update revalidates a pending magic link" do
    with_confirmation_nonce do |nonce|
      get sign_in_url(users.plain.magic_link.token)

      sign_in_as users.plain

      refute_increments(User::Session) { patch sign_in_index_url, params: { confirmation_nonce: nonce } }
      assert_redirected_to new_sign_in_url
    end
  end

  test "update rejects a stale confirmation page" do
    with_confirmation_nonce do
      get sign_in_url(users.owner.magic_link.token)

      refute_increments User::Session do
        patch sign_in_index_url, params: { confirmation_nonce: SecureRandom.hex }
      end
      assert_redirected_to new_sign_in_url
    end
  end

  test "show and update with expired magic link" do
    token = users.plain.magic_link.token
    travel 15.minutes + 1.second

    get sign_in_url(token)
    assert_redirected_to new_sign_in_url

    with_confirmation_nonce do |nonce|
      get sign_in_url(users.plain.magic_link.token)
      follow_redirect!
      travel 15.minutes + 1.second

      refute_increments(User::Session) { patch sign_in_index_url, params: { confirmation_nonce: nonce } }
      assert_redirected_to new_sign_in_url
    end
  end

  private
    def with_confirmation_nonce(nonce = "abcdef")
      Confirmation::Token.with(nonce:) { yield nonce }
    end
end
