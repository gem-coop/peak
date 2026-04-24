class ChangeNamespaceIndexesAccessDefaultToPublic < ActiveRecord::Migration[8.1]
  def change
    change_column_default :namespace_indexes, :access, from: "external", to: "public"
  end
end
