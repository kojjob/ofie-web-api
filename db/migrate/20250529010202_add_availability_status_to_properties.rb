class AddAvailabilityStatusToProperties < ActiveRecord::Migration[8.0]
  def up
    # Add the new availability_status column with default value
    add_column :properties, :availability_status, :integer, default: 0, null: false

    # Migrate existing data: available=true -> 0 (available), available=false -> 1 (rented)
    execute <<-SQL
      UPDATE properties#{' '}
      SET availability_status = CASE#{' '}
        WHEN available = true THEN 0#{' '}
        WHEN available = false THEN 1#{' '}
      END
    SQL

    # Remove the old available column
    remove_column :properties, :available

    # Add index for the new column
    add_index :properties, :availability_status
  end

  def down
    # Add back the available column
    add_column :properties, :available, :boolean, default: true, null: false

    # Migrate data back: 0 (available) -> true, 1 (rented) -> false
    execute <<-SQL
      UPDATE properties#{' '}
      SET available = CASE#{' '}
        WHEN availability_status = 0 THEN true#{' '}
        WHEN availability_status = 1 THEN false#{' '}
      END
    SQL

    # Remove the availability_status column and its index
    remove_index :properties, :availability_status
    remove_column :properties, :availability_status

    # Add back the index for available column
    add_index :properties, :available
  end
end
