class CreateNamespaceGemVersionMetadata < ActiveRecord::Migration[8.2]
  def change
    create_table :namespace_gem_version_metadata do |t|
      t.references :version, null: false, index: { unique: true }
      t.string :checksum, null: false
      t.string :ruby, null: false
      t.string :rubygems

      t.timestamps
    end
  end
end
