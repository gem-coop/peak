require "test_helper"

class Peak::CommandTest < ActiveSupport::TestCase
  test "trusted_publisher_workflow includes id-token permission, host and gem" do
    yaml = Peak::Command.trusted_publisher_workflow(host: "https://gem.coop/@gemcoop", gem: "peak")
    assert_includes yaml, "id-token: write"
    assert_includes yaml, "https://gem.coop/@gemcoop"
    assert_includes yaml, "peak.gemspec"
    assert_includes yaml, "gem push --host https://gem.coop/@gemcoop"
  end
end
