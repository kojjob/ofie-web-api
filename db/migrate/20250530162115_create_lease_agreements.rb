class CreateLeaseAgreements < ActiveRecord::Migration[8.0]
  def change
    create_table :lease_agreements, id: :uuid do |t|
      t.uuid :rental_application_id, null: false
      t.uuid :landlord_id, null: false
      t.uuid :tenant_id, null: false
      t.uuid :property_id, null: false
      t.date :lease_start_date, null: false
      t.date :lease_end_date, null: false
      t.decimal :monthly_rent, precision: 10, scale: 2, null: false
      t.decimal :security_deposit_amount, precision: 10, scale: 2
      t.string :status, default: 'draft'
      t.text :terms_and_conditions
      t.datetime :signed_by_tenant_at
      t.datetime :signed_by_landlord_at
      t.string :document_url
      t.string :lease_number
      t.json :additional_terms

      t.timestamps
    end

    add_foreign_key :lease_agreements, :rental_applications, column: :rental_application_id
    add_foreign_key :lease_agreements, :users, column: :landlord_id
    add_foreign_key :lease_agreements, :users, column: :tenant_id
    add_foreign_key :lease_agreements, :properties, column: :property_id

    add_index :lease_agreements, :rental_application_id, unique: true
    add_index :lease_agreements, :landlord_id
    add_index :lease_agreements, :tenant_id
    add_index :lease_agreements, :property_id
    add_index :lease_agreements, :status
    add_index :lease_agreements, :lease_start_date
    add_index :lease_agreements, :lease_end_date
    add_index :lease_agreements, :lease_number, unique: true
  end
end
