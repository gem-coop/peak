class CreateNamespaceIndexes < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_indexes do |t|
      t.references :namespace, null: false
      t.text :versions_contents, null: false, default: "---\n"
      t.string :access, null: false, default: "external"
      t.datetime :last_compacted_at, null: false

      t.timestamps
    end
  end
end
