class CreateNamespaceGemSearchIndexes < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_gem_search_indexes do |t|
      t.references :gem, index: {unique: true}, null: false
      t.text :content, null: false, default: ""

      t.index "to_tsvector('simple', content)", using: :gin, name: "search_indexes_tsvector_index"

      t.timestamps
    end
  end
end
