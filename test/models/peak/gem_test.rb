require "test_helper"

class Peak::GemTest < ActiveSupport::TestCase
  test "version splitting with extra dash" do
    assert_equal ["active_job-performs", "1.0.0"], Peak::Gem.version("active_job-performs-1.0.0.gem")
    assert_equal ["active_job-performs", "1.0.0-arm64-darwin-23"], Peak::Gem.version("active_job-performs-1.0.0-arm64-darwin-23.gem")
  end
end
