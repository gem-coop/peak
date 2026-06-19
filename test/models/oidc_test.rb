require "test_helper"

class OIDCTest < ActiveSupport::TestCase
  test "table name prefix" do
    assert_equal "oidc_", OIDC.table_name_prefix
  end

  test "jwt is loadable" do
    assert defined?(JWT)
  end
end
