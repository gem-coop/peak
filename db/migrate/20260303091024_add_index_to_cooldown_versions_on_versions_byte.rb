class AddIndexToCooldownVersionsOnVersionsByte < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :cooldown_versions, :versions_byte, algorithm: :concurrently
  end
end
