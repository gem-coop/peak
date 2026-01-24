class AddPublishedAtToNamespaceGemVersions < ActiveRecord::Migration[8.2]
  def change
    add_column :namespace_gem_versions, :published_at, :datetime

    up_only { Namespace::Gem::Version.update_all published_at: Time.current }
    change_column_null :namespace_gem_versions, :published_at, false
  end
end
