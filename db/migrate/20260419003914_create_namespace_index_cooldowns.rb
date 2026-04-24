class CreateNamespaceIndexCooldowns < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_index_cooldowns do |t|
      t.references :index, null: false, foreign_key: {to_table: "namespace_indexes"}
      t.integer :days_delayed, null: false, default: 2
      t.datetime :last_compacted_at, null: false
      t.text :versions_contents, default: "---\n", null: false

      t.timestamps
    end
  end
end
