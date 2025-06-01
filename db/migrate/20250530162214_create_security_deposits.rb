class CreateSecurityDeposits < ActiveRecord::Migration[8.0]
  def change
    create_table :security_deposits, id: :uuid do |t|
      t.uuid :lease_agreement_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, default: 'pending' # 'pending', 'collected', 'refunded', 'partially_refunded'
      t.datetime :collected_at
      t.datetime :refunded_at
      t.decimal :refund_amount, precision: 10, scale: 2
      t.json :deductions # Array of {description, amount, date}
      t.string :stripe_payment_intent_id
      t.string :stripe_refund_id
      t.text :refund_reason
      t.text :collection_notes
      t.json :inspection_report

      t.timestamps
    end

    add_foreign_key :security_deposits, :lease_agreements, column: :lease_agreement_id

    add_index :security_deposits, :lease_agreement_id, unique: true
    add_index :security_deposits, :status
    add_index :security_deposits, :collected_at
    add_index :security_deposits, :refunded_at
    add_index :security_deposits, :stripe_payment_intent_id
  end
end
