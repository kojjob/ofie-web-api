class ChangePostIdToUuid < ActiveRecord::Migration[8.0]
  def up
    # Enable pgcrypto extension for UUID generation
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    # Add new UUID column
    add_column :posts, :uuid, :uuid, default: 'gen_random_uuid()', null: false

    # Update existing records to have UUIDs
    execute <<-SQL
      UPDATE posts SET uuid = gen_random_uuid();
    SQL

    # Change primary key
    execute <<-SQL
      ALTER TABLE posts DROP CONSTRAINT posts_pkey;
      ALTER TABLE posts ADD PRIMARY KEY (uuid);
    SQL

    # Update foreign key in ActionText (rich text content)
    if table_exists?(:action_text_rich_texts)
      execute <<-SQL
        ALTER TABLE action_text_rich_texts DROP CONSTRAINT IF EXISTS fk_rails_4c8f5f7b1b;
        ALTER TABLE action_text_rich_texts ADD COLUMN record_uuid UUID;
        UPDATE action_text_rich_texts
        SET record_uuid = posts.uuid
        FROM posts
        WHERE action_text_rich_texts.record_type = 'Post'
        AND action_text_rich_texts.record_id::text = posts.id::text;
        ALTER TABLE action_text_rich_texts DROP COLUMN record_id;
        ALTER TABLE action_text_rich_texts RENAME COLUMN record_uuid TO record_id;
      SQL
    end

    # Drop old id column and rename uuid to id
    remove_column :posts, :id
    rename_column :posts, :uuid, :id

    # Update author_id foreign key if needed
    execute <<-SQL
      ALTER TABLE posts DROP CONSTRAINT IF EXISTS fk_rails_3a3c826f54;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
