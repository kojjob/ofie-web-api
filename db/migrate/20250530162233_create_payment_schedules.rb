class CreatePaymentSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_schedules, id: :uuid do |t|
      t.uuid :lease_agreement_id, null: false
      t.string :payment_type, null: false # 'rent', 'utility', 'maintenance_fee', etc.
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :frequency, null: false # 'monthly', 'weekly', 'quarterly', 'annually'
      t.date :start_date, null: false
      t.date :end_date
      t.date :next_payment_date, null: false
      t.boolean :is_active, default: true
      t.boolean :auto_pay, default: false
      t.integer :day_of_month # For monthly payments, which day of month
      t.text :description
      t.json :metadata

      t.timestamps
    end

    add_foreign_key :payment_schedules, :lease_agreements, column: :lease_agreement_id

    add_index :payment_schedules, :lease_agreement_id
    add_index :payment_schedules, :payment_type
    add_index :payment_schedules, :next_payment_date
    add_index :payment_schedules, :is_active
    add_index :payment_schedules, :auto_pay
    add_index :payment_schedules, [ :lease_agreement_id, :payment_type ]
  end
end
