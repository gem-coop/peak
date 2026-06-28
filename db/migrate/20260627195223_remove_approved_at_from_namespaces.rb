class RemoveApprovedAtFromNamespaces < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :namespaces, :approved_at, :datetime }
  end
end
