require "test_helper"

class Namespaces::TrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  def index_url = namespace_trusted_publishers_url(namespace: namespaces.gemcoop.name)
  def valid_params
    { trusted_publisher: { gem_name: "brand_new_gem", repository_owner: "gem-coop",
        repository_name: "brand_new_gem", workflow_filename: "release.yml" } }
  end

  test "owner can reserve a pending publisher" do
    sign_in_as users.owner
    assert_increments namespaces.gemcoop.trusted_publishers do
      post index_url, params: valid_params
    end
    publisher = namespaces.gemcoop.trusted_publishers.order(:created_at).last
    assert publisher.pending?
    assert_equal "brand_new_gem", publisher.gem_name
  end

  test "non-owner is redirected" do
    sign_in_as users.plain
    refute_increments namespaces.gemcoop.trusted_publishers do
      post index_url, params: valid_params
    end
    assert_response :redirect
  end

  test "owner can list pending publishers" do
    sign_in_as users.owner
    get index_url
    assert_response :success
  end

  test "non-owner sees the owner-gate alert via flash" do
    sign_in_as users.plain
    get namespace_trusted_publishers_url(namespace: namespaces.gemcoop.name)
    follow_redirect!
    assert_includes response.body, "must be an owner"
  end
end
