namespace = namespaces.create :gemcoop, name: "@gemcoop"

accesses.with namespace: do
  _1.owner.create user: users.create(:kasper, name: "Kasper")
  _1.plain.create user: users.create(:plain, name: "Plain")
end

gems.create name: "oaken", namespace:
