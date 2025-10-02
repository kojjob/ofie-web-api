class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content
      t.text :excerpt
      t.uuid :author_id, null: false
      t.string :category
      t.text :tags
      t.boolean :published, default: false
      t.datetime :published_at
      t.integer :views_count, default: 0
      t.integer :comments_count, default: 0

      t.timestamps
    end

    add_foreign_key :posts, :users, column: :author_id
    add_index :posts, :author_id
    add_index :posts, :slug, unique: true
    add_index :posts, :published
    add_index :posts, :category
    add_index :posts, :published_at
  end
end
