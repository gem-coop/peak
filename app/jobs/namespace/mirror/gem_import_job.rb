class Namespace::Mirror::GemImportJob < ApplicationJob
  import_queues = %w[import_1 import_2 import_3 import_4].cycle
  queue_as { import_queues.next }

  def perform(name:, namespace_id:)
    namespace = Namespace.find(namespace_id)
    namespace.gems.find_by!(name:).imports.import_all(namespace.stable_index)
  end
end
