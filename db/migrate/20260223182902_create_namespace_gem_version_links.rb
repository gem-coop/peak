class CreateNamespaceGemVersionLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_gem_version_links do |t|
      t.string :key, null: false
      t.string :value, null: false
      t.index [:key, :value], unique: true, name: "namespace_gem_version_links_uniqueness"

      t.timestamps
    end
  end
end
