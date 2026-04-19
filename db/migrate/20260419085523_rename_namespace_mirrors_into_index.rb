class RenameNamespaceMirrorsIntoIndex < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      rename_table :namespace_mirrors, :namespace_index_mirrors
    end
  end
end
