class MoveNamespaceGemVersionsIndexToNamespace < ActiveRecord::Migration[8.1]
  def change
    safety_assured {
      remove_index :namespace_gem_versions, [:gem_id, :ref], name: "index_namepace_gem_versions_uniqueness", unique: true
      add_index :namespace_gem_versions, [:gem_id, :index_id, :ref], name: "index_namepace_gem_versions_uniqueness", unique: true
    }
  end
end
