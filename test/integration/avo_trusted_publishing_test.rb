require "test_helper"

class AvoTrustedPublishingTest < ActionDispatch::IntegrationTest
  # Avo is only mounted when the :avo bundler group is loaded (Peak.avo?).
  setup { skip "Avo not loaded" unless Peak.avo? }

  def auth = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(*avo_credentials) }
  def avo_credentials = [ENV.fetch("ADMIN_USERNAME", "gem-coop"), ENV.fetch("ADMIN_PASSWORD", "")]

  test "trusted publishers index renders" do
    get "/avo/resources/trusted_publishers", headers: auth
    assert_includes [200, 302], response.status
  end
end
