class AddHasExtensionsToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :namespace_gem_versions, :has_extensions, :boolean
  end
end
