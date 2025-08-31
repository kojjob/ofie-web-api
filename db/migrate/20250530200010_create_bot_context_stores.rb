# Migration to create bot context store table
class CreateBotContextStores < ActiveRecord::Migration[8.0]
  def change
    create_table :bot_context_stores do |t|
      t.references :user, null: false, foreign_key: true, index: true, type: :uuid
      t.references :conversation, null: true, foreign_key: true, index: true, type: :bigint
      t.string :session_id, null: false, index: true
      t.json :context_data, null: false
      t.timestamps

      t.index [ :user_id, :conversation_id ], unique: true, name: 'index_bot_context_on_user_and_conversation'
      t.index :updated_at
    end
  end
end
