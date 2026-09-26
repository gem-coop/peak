class ReindexNamespaceGemSearchIndexAsEnglish < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :namespace_gem_search_indexes, "to_tsvector('simple', content)", using: :gin, name: "search_indexes_tsvector_index"
    add_index :namespace_gem_search_indexes, "to_tsvector('english', content)", using: :gin, name: "search_indexes_tsvector_index", algorithm: :concurrently
  end
end
