# Migration to create bot feedback table
class CreateBotFeedback < ActiveRecord::Migration[8.0]
  def change
    create_table :bot_feedbacks do |t|
      t.references :user, null: false, foreign_key: true, index: true, type: :uuid
      t.references :message, null: false, foreign_key: true, index: true, type: :bigint
      t.string :feedback_type, null: false, index: true
      t.text :details
      t.json :context
      t.timestamps

      t.index :created_at
      t.index [ :feedback_type, :created_at ]
    end
  end
end
