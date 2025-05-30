class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.text :content, null: false
      t.string :message_type, default: 'text'
      t.boolean :read, default: false
      t.string :attachment_url

      t.timestamps
    end

    add_index :messages, :created_at
    add_index :messages, [ :conversation_id, :created_at ]
    add_index :messages, [ :sender_id, :read ]
  end
end
