class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments, id: :uuid do |t|
      t.uuid :lease_agreement_id, null: false
      t.uuid :user_id, null: false
      t.uuid :payment_method_id
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :payment_type, null: false # 'rent', 'security_deposit', 'late_fee', 'utility', etc.
      t.string :status, default: 'pending' # 'pending', 'processing', 'succeeded', 'failed', 'canceled'
      t.string :stripe_payment_intent_id
      t.string :stripe_charge_id
      t.string :description
      t.date :due_date
      t.datetime :paid_at
      t.string :failure_reason
      t.json :metadata
      t.string :payment_number

      t.timestamps
    end

    add_foreign_key :payments, :lease_agreements, column: :lease_agreement_id
    add_foreign_key :payments, :users, column: :user_id
    add_foreign_key :payments, :payment_methods, column: :payment_method_id

    add_index :payments, :lease_agreement_id
    add_index :payments, :user_id
    add_index :payments, :payment_method_id
    add_index :payments, :status
    add_index :payments, :payment_type
    add_index :payments, :due_date
    add_index :payments, :paid_at
    add_index :payments, :stripe_payment_intent_id, unique: true
    add_index :payments, :payment_number, unique: true
  end
end
