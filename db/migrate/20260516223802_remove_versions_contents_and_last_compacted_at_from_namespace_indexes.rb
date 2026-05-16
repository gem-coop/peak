class RemoveVersionsContentsAndLastCompactedAtFromNamespaceIndexes < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :namespace_indexes, :versions_contents, :text
      remove_column :namespace_indexes, :last_compacted_at, :datetime
    end
  end
end
