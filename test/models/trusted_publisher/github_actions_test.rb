require "test_helper"

class TrustedPublisher::GitHubActionsTest < ActiveSupport::TestCase
  def build(**overrides)
    TrustedPublisher::GitHubActions.new({
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak",
      workflow_filename: "release.yml"
    }.merge(overrides))
  end

  test "pending? and target_index" do
    assert_not build.pending?
    assert_equal gems.peak.index, build.target_index

    pending = build(gem: nil)
    assert pending.pending?
    assert_equal namespaces.gemcoop.default_index, pending.target_index
  end

  test "matches exact claims" do
    assert build.matches?(default_github_claims)
  end

  test "rejects wrong repository" do
    assert_not build.matches?(default_github_claims(repository: "evil/peak", repository_owner: "evil"))
  end

  test "rejects wrong workflow" do
    refute build.matches?(default_github_claims(
      job_workflow_ref: "gem-coop/peak/.github/workflows/evil.yml@refs/heads/main"))
  end

  test "environment is enforced only when configured" do
    assert build.matches?(default_github_claims(environment: "anything"))
    assert build(environment: "rubygems").matches?(default_github_claims(environment: "rubygems"))
    refute build(environment: "rubygems").matches?(default_github_claims(environment: "other"))
  end

  test "link_gem! converts a pending publisher" do
    pending = build(gem: nil)
    pending.save!
    pending.link_gem!(gems.peak)
    assert_equal gems.peak, pending.reload.gem
    assert_not pending.pending?
  end

  test "link_gem! ignores name mismatch" do
    pending = build(gem: nil, gem_name: "other")
    pending.save!
    pending.link_gem!(gems.peak)
    assert pending.reload.pending?
  end

  test "name is owner/repo" do
    assert_equal "gem-coop/peak", build.name
  end

  test "repository owner and name are folded to lowercase" do
    publisher = build(repository_owner: "Gem-Coop", repository_name: "Peak")
    assert_equal "gem-coop", publisher.repository_owner
    assert_equal "peak", publisher.repository_name
  end

  test "matches case-insensitively against claim casing" do
    assert build.matches?(default_github_claims(
      repository_owner: "Gem-Coop", repository: "Gem-Coop/Peak",
      job_workflow_ref: "Gem-Coop/Peak/.github/workflows/release.yml@refs/heads/main"))
  end

  test "rejects a duplicate publisher for the same workflow" do
    build.save!
    dup = build
    assert_not dup.valid?
    assert_predicate dup.errors[:repository_name], :any?
  end

  test "allows a second publisher differing by environment" do
    build(environment: "prod").save!
    assert build(environment: "staging").valid?
  end

  test "provider_label" do
    assert_equal "GitHub Actions", build.provider_label
    assert_equal "trusted publisher", TrustedPublisher.new.provider_label
  end
end
