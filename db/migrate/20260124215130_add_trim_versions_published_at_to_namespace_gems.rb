class AddTrimVersionsPublishedAtToNamespaceGems < ActiveRecord::Migration[8.1]
  def change
    add_column :namespace_gems, :trim_versions_published_at, :datetime
  end
end
