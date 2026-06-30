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

gems.with index: namespace.default_index do
  _1.parse :oaken, gems.oaken_lines

  peak = _1.create :peak, name: :peak
  versions.upload peak, ref: "0.1.0", created_by: users.owner
end

cooldowns.create :gemcoop, index: namespace.default_index
cooldowns.create :gemcoop_dev, index: indexes.gemcoop_dev
