class AddApprovedAtToNamespaces < ActiveRecord::Migration[8.1]
  def change
    add_column :namespaces, :approved_at, :datetime
    add_index :namespaces, :approved_at

    up_only { Namespace.update_all approved_at: Time.current }
  end
end
