class AddMetadataToNamespaceGemVersions < ActiveRecord::Migration[8.2]
  def change
    add_column :namespace_gem_versions, :checksum, :string
    add_column :namespace_gem_versions, :ruby, :string
    add_column :namespace_gem_versions, :rubygems, :string
  end
end
