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

  test "show" do
    token = users.plain.magic_link.token

    refute_increments(User::Session) { get sign_in_url(token) }
    assert_response :success
    assert_equal "strict-origin", response.headers["referrer-policy"]
    assert_dom("form") { |form| refute_pattern { form => { action: /.*\d+/ } } }

    sign_in_as users.plain

    refute_increments(User::Session) { get sign_in_url(token) }
    assert_redirected_to new_sign_in_url
  end

  test "update" do
    assert_increments User::Session do
      patch sign_in_index_url, params: { token: users.plain.magic_link.token }
    end
    assert_redirected_to dashboard_url
  end

  test "update creates session from magic link — with redirect_url" do
    assert_increments User::Session do
      patch sign_in_index_url(redirect_url: dashboard_url), params: { token: users.plain.magic_link.token }
    end
    assert_redirected_to dashboard_url
  end

  test "show + update with expired magic link" do
    token = users.plain.magic_link.token
    travel 15.minutes + 1.second

    get sign_in_url(token)
    assert_redirected_to new_sign_in_url

    refute_increments(User::Session) { patch sign_in_index_url, params: { token: } }
    assert_redirected_to new_sign_in_url
  end
end
