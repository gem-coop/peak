class CreateNamespaceSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_submissions do |t|
      t.references :owner, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "pending"
      t.references :adjudicated_by, null: true
      t.datetime :adjudicated_at

      t.timestamps
    end

    add_index :namespace_submissions, :name, unique: true, where: "status != 'pending'"

    up_only do
      Namespace.includes(:owners).find_each do |namespace|
        owner_id = namespace.owners.order(:created_at).pick(:user_id) || Peak.system_user.id

        namespace.submissions.approved.create! owner_id:,
          adjudicated_by: Peak.system_user, # We don't have granular tracking for any previous approvals
          adjudicated_at: namespace.approved_at
      end
    end
  end
end
