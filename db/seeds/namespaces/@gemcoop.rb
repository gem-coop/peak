owner = users.create(:owner, name: "Owner", email_address: "owner@example.com")
namespace = namespaces.create_approved :gemcoop, owner:, name: "@gemcoop"
# Created & managed by subscription eventually
indexes.public_access.create :gemcoop_dev, namespace:, slug: :dev
indexes.private_access.create :gemcoop_private, namespace:, slug: :private

accesses.with namespace: do
  _1.plain.create :plain, user: users.create(:plain, name: "Plain", email_address: "plain@example.com")
  user_push_keys.label gemcoop_plain: users.plain.create_push_key

  _1.plain.create user: users.unverified.create(:unverified_plain, name: "Unverified", email_address: "unverified@example.com")
end

gems.with namespace: do
  index = namespace.stable_index

  gem = _1.parse :oaken, index, gems.oaken_lines
  gem.versions.latest.update! summary: "Oaken aims to blend your Fixtures/Factories and levels up your database seeds."
  gem.reload.reindex

  peak = _1.create :peak, name: :peak
  versions.upload peak, ref: "0.1.0", index:, created_by: users.owner
end

cooldowns.create :gemcoop, index: namespace.stable_index
cooldowns.create :gemcoop_dev, index: indexes.gemcoop_dev
