class CreatePropertyComments < ActiveRecord::Migration[8.0]
  def change
    create_table :property_comments, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :property, null: false, foreign_key: true, type: :uuid
      t.references :parent, null: true, foreign_key: { to_table: :property_comments }, type: :uuid
      t.text :content, null: false
      t.boolean :edited, default: false
      t.datetime :edited_at
      t.integer :likes_count, default: 0
      t.boolean :flagged, default: false
      t.string :flagged_reason
      t.datetime :flagged_at

      t.timestamps
    end

    add_index :property_comments, [:property_id, :created_at]
    add_index :property_comments, [:user_id, :created_at]
    add_index :property_comments, :parent_id
    add_index :property_comments, :flagged

    add_check_constraint :property_comments, "length(content) >= 1 AND length(content) <= 2000", name: "content_length_check"
  end
end
