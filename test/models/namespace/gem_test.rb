require "test_helper"

class Namespace::GemTest < ActiveSupport::TestCase
  test "referrants" do
    version = versions.by gems.activesupport, ref: "8.1.1"
    referrant = version.referrants.sole

    assert referrant.eq?
    assert_equal "8.1.1", referrant.ref
    assert_includes gems.activesupport.referrants, referrant
  end
end
