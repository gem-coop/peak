class AddIndexToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :namespace_gem_versions, :index, null: true, index: {algorithm: :concurrently}

    up_only { Namespace::Gem::Version.includes(:gem).find_each { _1.update index_id: _1.gem.index_id } }

    safety_assured { change_column_null :namespace_gem_versions, :index_id, false }
  end
end
