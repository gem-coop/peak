class CreateCooldownVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :cooldown_versions do |t|
      t.string :name
      t.string :version
      t.bigint :versions_byte
      t.bigint :info_byte

      t.timestamps
      t.index [:name, :version], unique: true
      t.index :created_at
    end
  end
end
