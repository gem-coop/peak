class CreateNamespaceGemVersionReferences < ActiveRecord::Migration[8.2]
  def change
    create_table :namespace_gem_version_references do |t|
      t.references :source, null: false
      t.references :linked, null: false
      t.string :operator, null: false

      t.index [:source_id, :linked_id, :operator], unique: true, name: "namespace_gem_version_references_uniqueness"
      t.timestamps
    end
  end
end
