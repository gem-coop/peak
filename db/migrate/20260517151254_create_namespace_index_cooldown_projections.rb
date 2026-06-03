class CreateNamespaceIndexCooldownProjections < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_index_cooldown_projections do |t|
      t.references :cooldown, null: false
      t.references :version, null: false, index: false
      t.datetime :append_at, null: false
      t.index [:cooldown_id, :version_id], unique: true

      t.timestamps
    end
  end
end
