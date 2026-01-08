namespace = namespaces.create :gemcoop, name: "Gem Coop"

users.create :kasper, name: "Kasper", namespaces: [namespace]
