class CreateNamespaceIndexManifests < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_index_manifests do |t|
      t.references :author, null: false, polymorphic: true, index: { unique: true }
      t.text :contents, null: false, default: ""
      t.datetime :compacted_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    up_only { Namespace::Index.find_each { _1.create_manifest.compact } }
  end
end
