require "test_helper"

class Peak::Terms::AcceptancesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as @user = users.plain }

  test "get new" do
    get new_terms_acceptances_url
    assert_response :success
  end

  test "create accepting" do
    post terms_acceptances_url(terms.latest), params: { acceptance: { accepted: true, time_zone: "America/Chicago" } }
    assert_response :success

    Peak::Terms.acceptance_for(@user).tap do |acceptance|
      assert acceptance.accepted?
      assert_equal "America/Chicago", acceptance.time_zone
      assert acceptance.captured_at.past?
      assert acceptance.sha?
    end
  end

  test "create redirects to latest terms if trying to accept outdated terms" do
    post terms_acceptances_url(terms.outdated)
    assert_redirected_to new_terms_acceptances_url
    refute Peak::Terms.acceptance_for(@user).accepted?
  end
end
