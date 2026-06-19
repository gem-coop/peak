require "test_helper"

class TrustedPublisher::PushKeyTest < ActiveSupport::TestCase
  setup do
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    @key = @publisher.push_keys.create!
  end

  test "token has prefix" do
    assert @key.token.start_with?(TrustedPublisher::PushKey::PREFIX)
  end

  test "default expiry is 30 minutes" do
    freeze_time
    assert_equal 30.minutes.from_now, @publisher.push_keys.build.expires_at
  end

  test "active scope and predicates" do
    assert_includes TrustedPublisher::PushKey.active, @key
    travel @key.expires_at.to_i + 1.second
    refute @key.active?
    assert_includes TrustedPublisher::PushKey.expired, @key
  end

  test "name and scopes" do
    assert_equal "trusted-publisher:peak", @key.name
    assert_equal %w[push_rubygem], @key.scopes
  end
end
