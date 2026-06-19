require "test_helper"

class Namespace::Gem::VersionTest < ActiveSupport::TestCase
  test "versions" do
    refs = gems.oaken.versions.pluck :ref
    assert_includes refs, "0.9.1"
    assert_includes refs, "1.0.0"
  end

  test "checksum parsing" do
    version = versions.by gems.actionview, ref: "8.1.0"
    assert_equal "b7e8770a5aacd389a3c04916d29609a53459447fcbf747150437136d44c1d1f3", version.checksum
  end

  test "created_by can be a trusted publisher" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")

    version = versions.by gems.peak, ref: "0.1.0"
    version.update!(created_by: publisher)
    assert_equal publisher, version.reload.created_by
  end
end
