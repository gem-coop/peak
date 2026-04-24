class AddMirrorLastLineAndCreatedAt < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      change_table :namespace_index_mirrors do |t|
        t.datetime :last_created_at
        t.string :last_line
      end
    end
  end
end
