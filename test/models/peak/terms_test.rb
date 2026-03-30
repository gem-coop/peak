require "test_helper"

class Peak::TermsTest < ActiveSupport::TestCase
  test "not immutable until finalized" do
    refute terms.create(content: "drafted").reload.readonly?
    assert terms.latest.readonly?
  end

  test "allows reacceptance" do
    acceptance = terms.latest.acceptance_for(users.plain)
    acceptance.capture accepted: false, time_zone: "America/Chicago"
    refute acceptance.accepted?

    assert_changes -> { acceptance.captured_at }, -> { acceptance.time_zone } do
      acceptance.capture accepted: true, time_zone: "Europe/Copenhagen"
    end
    assert acceptance.accepted?
  end
end
