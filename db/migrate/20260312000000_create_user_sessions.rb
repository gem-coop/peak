class CreateUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, index: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
