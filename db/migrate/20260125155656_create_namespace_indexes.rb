class CreateNamespaceIndexes < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_indexes do |t|
      t.references :namespace, null: false
      t.references :versions_blob
      t.string :access, null: false, default: "external"
      t.datetime :last_compacted_at, null: false

      t.timestamps
    end
  end
end
