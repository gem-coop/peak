class ChangeColumnNullIndexIdOnNamespaceGems < ActiveRecord::Migration[8.1]
  def change
    change_column_null :namespace_gems, :index_id, true
  end
end
