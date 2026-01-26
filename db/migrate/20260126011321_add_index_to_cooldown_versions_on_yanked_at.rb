class AddIndexToCooldownVersionsOnYankedAt < ActiveRecord::Migration[8.1]
  def change
    change_table :cooldown_versions do |t|
      t.index :yanked_at
      t.index [:yanked_at, :published_at]
    end
  end
end
