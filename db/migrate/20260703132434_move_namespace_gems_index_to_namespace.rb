class MoveNamespaceGemsIndexToNamespace < ActiveRecord::Migration[8.1]
  def change
    safety_assured {
      remove_index :namespace_gems, :index_id, name: "index_namespace_gems_on_index_id"
      remove_index :namespace_gems, [:index_id, :name], name: "index_namepace_gems_uniqueness", unique: true
      add_index    :namespace_gems, [:namespace_id, :name], name: "index_namepace_gems_uniqueness", unique: true
    }
  end
end
