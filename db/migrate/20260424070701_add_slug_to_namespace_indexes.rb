class AddSlugToNamespaceIndexes < ActiveRecord::Migration[8.1]
  def change
    StrongMigrations.disable_check :change_column_null_postgresql if defined?(StrongMigrations)
    StrongMigrations.disable_check :add_index if defined?(StrongMigrations)

    add_column :namespace_indexes, :slug, :string

    # Also rename external to public while we're at it.
    up_only { Namespace::Index.update_all slug: :default, access: :public }
    change_column_null :namespace_indexes, :slug, false

    add_index :namespace_indexes, [:namespace_id, :slug], unique: true, name: "namespace_index_uniqueness"
  end
end
