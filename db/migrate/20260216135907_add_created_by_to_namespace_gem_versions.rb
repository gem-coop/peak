class AddCreatedByToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    add_reference :namespace_gem_versions, :created_by

    up_only { Namespace::Gem::Version.update_all created_by_id: Peak.system_user.id }
    change_column_null :namespace_gem_versions, :created_by_id, false
  end
end
