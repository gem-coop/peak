namespace = namespaces.create :gemcoop, name: "@gemcoop"

accesses.with namespace: do
  _1.owner.create :owner, user: users.create(:kasper, name: "Owner")
  _1.plain.create :plain, user: users.create(:plain, name: "Plain")
end

gems.with(namespace:).parse :oaken, gems.oaken_lines
