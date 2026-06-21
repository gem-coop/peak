require "test_helper"

class OIDC::IdTokenTest < ActiveSupport::TestCase
  setup do
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
  end

  test "jti is unique per provider" do
    attrs = { provider: oidc_providers.github, trusted_publisher: @publisher, jti: "abc", claims: {} }
    OIDC::IdToken.create!(attrs)
    assert_raises(ActiveRecord::RecordInvalid) { OIDC::IdToken.create!(attrs) }
  end
end
