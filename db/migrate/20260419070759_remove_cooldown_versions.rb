class RemoveCooldownVersions < ActiveRecord::Migration[8.1]
  def change
    drop_table :cooldown_versions do |t|
      t.string :name
      t.string :version
      t.bigint :versions_byte
      t.bigint :info_byte
      t.datetime :published_at
      t.datetime :yanked_at

      t.timestamps
      t.index [:name, :version], unique: true
      t.index [:yanked_at, :published_at]
    end
  end
end
