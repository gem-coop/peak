class RemoveCooldownVersions < ActiveRecord::Migration[8.1]
  def change
    drop_table :cooldown_versions
  end
end
