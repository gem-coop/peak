class CreateNamespaceGemVersionNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_gem_version_nodes do |t|
      t.references :version, null: false, index: true
      t.references :reference, null: false

      t.timestamps
      t.index [:version_id, :reference_id], unique: true, name: "namespace_gem_version_nodes_uniqueness"
    end
  end
end
