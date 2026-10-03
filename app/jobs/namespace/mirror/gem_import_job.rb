class Namespace::Mirror::GemImportJob < ApplicationJob
  def perform(name:, namespace_id:)
    namespace = Namespace.find(namespace_id)
    namespace.gems.find_by!(name:).imports.import_all(namespace.stable_index)
  end
end
