class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.text :message, null: false
      t.string :notification_type, null: false
      t.boolean :read, default: false, null: false
      t.datetime :read_at
      t.string :url
      t.references :notifiable, polymorphic: true, null: true

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read ]
    add_index :notifications, [ :user_id, :created_at ]
    add_index :notifications, [ :notifiable_type, :notifiable_id ]
  end
end
