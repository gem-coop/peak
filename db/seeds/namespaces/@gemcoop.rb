namespace = namespaces.create :gemcoop, name: "@gemcoop"

accesses.with namespace: do
  _1.owner.create user: users.create(:kasper, name: "Kasper")
  _1.plain.create user: users.create(:plain, name: "Plain")
end

gems.with namespace_id: namespace.id do
  _1.parse "oaken",
    "0.9.1 |checksum:86c502949e539dd53e40e66664502c7a0bda537eccdfa9ae426f0c90c354ba03,ruby:>= 3.0.0",
    "1.0.0 |checksum:e89249bc4f6cd3ab9b5e3abdc06c377fa772e6bcb3005cc09ff044bb8d3f1dc2,ruby:>= 3.2"
end
