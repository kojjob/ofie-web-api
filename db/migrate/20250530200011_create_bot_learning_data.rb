# Migration to create bot learning data table
class CreateBotLearningData < ActiveRecord::Migration[8.0]
  def change
    create_table :bot_learning_data do |t|
      t.references :user, null: false, foreign_key: true, index: true, type: :uuid
      t.text :message, null: false
      t.string :intent, null: false, index: true
      t.decimal :confidence, precision: 5, scale: 4, null: false
      t.json :entities
      t.json :context
      t.string :session_id, null: false, index: true
      t.timestamps

      t.index :created_at
      t.index [ :intent, :confidence ]
      t.index [ :user_id, :created_at ]
    end
  end
end
