class CreateCommentLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_likes, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :property_comment, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :comment_likes, [ :user_id, :property_comment_id ], unique: true
    add_index :comment_likes, :property_comment_id
  end
end
