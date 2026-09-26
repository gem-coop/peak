class CreateBillingStripeEventReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :billing_stripe_event_receipts do |t|
      t.references :account, index: true
      t.string :type, null: false, index: true
      t.string :status, null: false, default: "pending", index: true
      t.jsonb :data, null: false

      t.timestamps
    end
  end
end
