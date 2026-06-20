require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "version_author renders a user's name" do
    version = versions.by gems.peak, ref: "0.1.0"
    assert_equal users.owner.name, version_author(version)
  end

  test "version_author renders a trusted publisher repo with marker" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    version = versions.by gems.peak, ref: "0.1.0"
    version.update!(created_by: publisher)

    html = version_author(version)
    assert_includes html, "gem-coop/peak"
    assert_includes html, "via GitHub Actions"
  end
end
