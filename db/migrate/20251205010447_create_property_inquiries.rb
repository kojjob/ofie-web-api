class CreatePropertyInquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :property_inquiries, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :property, null: false, foreign_key: true, type: :uuid
      t.references :user, null: true, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.text :message, null: false
      t.boolean :gdpr_consent, default: false
      t.integer :status, default: 0, null: false
      t.datetime :read_at
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :property_inquiries, :email
    add_index :property_inquiries, :status
    add_index :property_inquiries, :created_at
  end
end
