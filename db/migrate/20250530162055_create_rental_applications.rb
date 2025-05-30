class CreateRentalApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :rental_applications, id: :uuid do |t|
      t.uuid :property_id, null: false
      t.uuid :tenant_id, null: false
      t.string :status, default: 'pending'
      t.datetime :application_date, default: -> { 'CURRENT_TIMESTAMP' }
      t.date :move_in_date
      t.decimal :monthly_income, precision: 10, scale: 2
      t.string :employment_status
      t.text :previous_address
      t.text :references_contact
      t.text :additional_notes
      t.boolean :documents_verified, default: false
      t.integer :credit_score
      t.datetime :reviewed_at
      t.uuid :reviewed_by_id

      t.timestamps
    end

    add_foreign_key :rental_applications, :properties, column: :property_id
    add_foreign_key :rental_applications, :users, column: :tenant_id
    add_foreign_key :rental_applications, :users, column: :reviewed_by_id

    add_index :rental_applications, :property_id
    add_index :rental_applications, :tenant_id
    add_index :rental_applications, :status
    add_index :rental_applications, :application_date
  end
end
