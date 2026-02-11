require "test_helper"

class Peak::GemTest < ActiveSupport::TestCase
  test "version splitting with extra dash" do
    assert_equal ["active_job-performs", "1.0.0"], Peak::Gem.version("active_job-performs-1.0.0.gem")
  end
end
