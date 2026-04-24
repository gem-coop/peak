class CreateNamespaceGemCooldownInfos < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_gem_cooldown_infos do |t|
      t.string :checksum, default: "", null: false
      t.text :contents, default: "", null: false
      t.string :envelope, default: "", null: false
      t.references :gem, null: false, foreign_key: {to_table: "namespace_gems"}, index: true
      t.references :cooldown, null: false, foreign_key: {to_table: "namespace_index_cooldowns"}, index: true

      t.timestamps
    end
  end
end
