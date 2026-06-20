require "test_helper"

class Namespaces::Gems::TrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  def index_url = namespace_gem_trusted_publishers_url(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name)
  def valid_params
    { trusted_publisher: { repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml" } }
  end

  test "owner can create a trusted publisher" do
    sign_in_as users.owner
    assert_increments gems.peak.trusted_publishers do
      post index_url, params: valid_params
    end
    assert_response :redirect
    assert_equal "TrustedPublisher::GitHubActions", gems.peak.trusted_publishers.last.type
  end

  test "non-owner is redirected" do
    sign_in_as users.plain
    refute_increments gems.peak.trusted_publishers do
      post index_url, params: valid_params
    end
    assert_response :redirect
  end

  test "unauthenticated is redirected to sign in" do
    post index_url, params: valid_params
    assert_response :redirect
  end

  test "owner can list" do
    sign_in_as users.owner
    get index_url
    assert_response :success
  end

  test "index has a back-link to the gem profile" do
    sign_in_as users.owner
    get namespace_gem_trusted_publishers_url(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name)
    assert_select "a[href=?]", namespace_gem_path(namespaces.gemcoop, gems.peak, index: nil)
  end
end
