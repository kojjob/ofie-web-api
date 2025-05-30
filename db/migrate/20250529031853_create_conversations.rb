class CreateConversations < ActiveRecord::Migration[7.0]
  def change
    create_table :conversations do |t|
      t.references :landlord, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :tenant, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :property, null: false, foreign_key: true, type: :uuid
      t.string :subject
      t.string :status, default: 'active'
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, [ :landlord_id, :tenant_id, :property_id ], unique: true, name: 'index_conversations_on_participants_and_property'
    add_index :conversations, :last_message_at
    add_index :conversations, :status
  end
end
