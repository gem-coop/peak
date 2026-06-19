class MakeVersionCreatedByPolymorphic < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Constant default is PG-safe on a populated table and backfills existing rows to "User".
    add_column :namespace_gem_versions, :created_by_type, :string, null: false, default: "User"
    add_index :namespace_gem_versions, [:created_by_type, :created_by_id], algorithm: :concurrently
  end
end
