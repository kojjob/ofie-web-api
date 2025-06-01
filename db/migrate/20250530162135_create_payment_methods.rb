class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_methods, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :stripe_payment_method_id, null: false
      t.string :payment_type, null: false # 'card', 'bank_account', etc.
      t.string :last_four
      t.string :brand
      t.integer :exp_month
      t.integer :exp_year
      t.boolean :is_default, default: false
      t.string :billing_name
      t.json :billing_address

      t.timestamps
    end

    add_foreign_key :payment_methods, :users, column: :user_id

    add_index :payment_methods, :user_id
    add_index :payment_methods, :stripe_payment_method_id, unique: true
    add_index :payment_methods, [ :user_id, :is_default ]
  end
end
