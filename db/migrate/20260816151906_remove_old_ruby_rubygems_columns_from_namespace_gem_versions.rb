class RemoveOldRubyRubygemsColumnsFromNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    safety_assured {
      remove_column :namespace_gem_versions, :ruby_old, :string
      remove_column :namespace_gem_versions, :rubygems_old, :string
    }
  end
end
