class RemoveIndexIdOnNamespaceGems < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_reference :namespace_gems, :index }
  end
end
