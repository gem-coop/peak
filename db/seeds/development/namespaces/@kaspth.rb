namespace = namespaces.create name: "@kaspth"

user = users.create name: "Kasper", email_address: "kasper@example.com"
namespace.accesses.owner.find_or_create_by(user:)

gems.with index: namespace.default_index do
  _1.import "oaken"
  _1.import "active_record-associated_object"
  _1.import "active_job-performs"
  _1.import "action_controller-stashed_redirects"
end
