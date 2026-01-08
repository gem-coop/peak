class CreateNamespaceGems < ActiveRecord::Migration[8.2]
  def change
    create_table :namespace_gems do |t|
      t.string :name, null: false
      t.references :namespace, null: false

      t.timestamps
      t.index [:name, :namespace_id], unique: true, name: "index_namepace_gems_uniqueness"
    end
  end
end
