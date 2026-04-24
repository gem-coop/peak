class AddIndexToNamespaceGems < ActiveRecord::Migration[8.1]
  def change
    add_reference :namespace_gems, :index
    remove_index :namespace_gems, [:namespace_id, :name], unique: true, name: "index_namepace_gems_uniqueness"
    add_index :namespace_gems, [:index_id, :name], unique: true, name: "index_namepace_gems_uniqueness"

    up_only do
      Namespace.find_each do |ns|
        index_id = ns.create_default_index.id
        Namespace::Gem.where(namespace: ns).update_all(index_id:)
      end
    end

    change_column_null :namespace_gems, :index_id, false
  end
end
