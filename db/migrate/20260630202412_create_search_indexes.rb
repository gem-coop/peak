class CreateSearchIndexes < ActiveRecord::Migration[8.1]
  def change
    create_table :search_indexes do |t|
      t.references :record, polymorphic: true, index: {unique: true}, null: false
      t.references :namespace, null: false
      t.text :content, null: false, default: ""

      t.index "to_tsvector('simple', content)", using: :gin, name: "search_indexes_tsvector_index"

      t.timestamps
    end
  end
end
