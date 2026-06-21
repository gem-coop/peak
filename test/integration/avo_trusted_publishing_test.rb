require "test_helper"

class AvoTrustedPublishingTest < ActionDispatch::IntegrationTest
  # Avo is only mounted when the :avo bundler group is loaded (Peak.avo?).
  setup do
    skip "Avo not loaded" unless Peak.avo?

    # Avo phones home to its licensing service while rendering; neutralize it so
    # WebMock doesn't block the request (it has no bearing on what we're testing).
    WebMock.stub_request(:any, /avohq\.io/).to_return(
      status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
  end

  def auth = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(*avo_credentials) }
  def avo_credentials = [ENV.fetch("ADMIN_USERNAME", "gem-coop"), ENV.fetch("ADMIN_PASSWORD", "")]

  test "trusted publishers index renders" do
    get "/avo/resources/trusted_publishers", headers: auth
    assert_includes [200, 302], response.status
  end
end
