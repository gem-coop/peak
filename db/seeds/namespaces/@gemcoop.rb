namespace = namespaces.create :gemcoop, name: "@gemcoop"

accesses.with namespace: do
  _1.owner.create :owner, user: users.create(:kasper, name: "Owner")
  _1.plain.create :plain, user: users.create(:plain, name: "Plain")
end

gems.with index: namespace.external_index do
  _1.parse :oaken, gems.oaken_lines

  peak = _1.create :peak, name: :peak
  versions.upload peak, ref: "0.1.0"
end
