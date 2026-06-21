require "test_helper"

class Namespaces::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "get show" do
    get namespace_url(namespaces.gemcoop)
    assert_response :success
    assert_dom "article", Regexp.new(gems.oaken.name)
  end

  test "get show with no gems" do
    get namespace_url(namespaces.blank)
    assert_response :success

    namespaces.blank.default_index.gems.create name: "unversioned"

    get namespace_url(namespaces.blank)
    assert_response :success
    assert_not_dom "article", "unversioned"
  end

  test "renders a version authored by a trusted publisher" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    versions.by(gems.peak, ref: "0.1.0").update!(created_by: publisher)

    get namespace_url(namespaces.gemcoop.name)
    assert_response :success
    assert_includes response.body, "gem-coop/peak"
  end

  test "owner sees the pending trusted publishers link" do
    sign_in_as users.owner
    get namespace_url(namespaces.gemcoop.name)
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name)
  end

  test "non-owner does not see the pending trusted publishers link" do
    sign_in_as users.plain
    get namespace_url(namespaces.gemcoop.name)
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name), count: 0
  end
end
