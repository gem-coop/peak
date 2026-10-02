namespace = namespaces.create name: "@kaspth"

user = users.create name: "Kasper", email_address: "kasper@example.com"
namespace.accesses.owner.find_or_create_by(user:)

namespaces.mirror namespace, %w[oaken active_record-associated_object active_job-performs action_controller-stashed_redirects]

p ApplicationJob.queue_adapter
