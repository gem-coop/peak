class RemoveTrimVersionsPublishedAtFromNamespaceGems < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :namespace_gems, :trim_versions_published_at, :string }
  end
end
