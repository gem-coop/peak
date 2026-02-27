class ReviseNamespaceGemVersionsUniqueness < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :namespace_gem_versions, %i[gem_id ref], unique: true, name: "index_namepace_gem_versions_uniqueness"
    add_index :namespace_gem_versions, %i[gem_id platform_id ref], unique: true, name: "index_namepace_gem_versions_uniqueness", algorithm: :concurrently
  end
end
