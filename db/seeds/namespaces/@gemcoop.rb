namespace = namespaces.create :gemcoop, name: "@gemcoop"
namespace.indexes.dev_access.create
namespace.indexes.private_access.create

accesses.with namespace: do
  _1.owner.create :owner, user: users.create(:owner, name: "Owner", email_address: "owner@example.com")
  _1.plain.create :plain, user: users.create(:plain, name: "Plain", email_address: "plain@example.com")
  users.plain.create_push_key
end

gems.with index: namespace.external_index do
  _1.parse :oaken, gems.oaken_lines

  peak = _1.create :peak, name: :peak
  versions.upload peak, ref: "0.1.0", created_by: users.owner
end
