require "test_helper"

class Namespaces::Gems::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_dom "section li", /#{gems.peak.versions.first.ref}/
  end

  test "renders a version authored by a trusted publisher" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    versions.by(gems.peak, ref: "0.1.0").update!(created_by: publisher)

    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_includes response.body, "gem-coop/peak"
    assert_includes response.body, "via GitHub Actions"
  end
end
