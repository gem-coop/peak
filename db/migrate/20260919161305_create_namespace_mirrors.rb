class CreateNamespaceMirrors < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_mirrors do |t|
      t.references :namespace, null: false, foreign_key: true
      t.string :url, null: false
      t.boolean :enabled, default: true, null: false
      t.integer :last_seen_line_no
      t.string :last_seen_line_end
      t.timestamps
    end
  end
end
