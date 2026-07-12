class RenameDefaultIndexToStableIndexOnNamespaceIndexes < ActiveRecord::Migration[8.1]
  def change
    Namespace::Index.where(slug: :default).update_all(slug: :stable)
  end
end
