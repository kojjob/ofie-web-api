class CreateLeaseClauses < ActiveRecord::Migration[8.0]
  def change
    create_table :lease_clauses, id: :uuid do |t|
      t.string :category, null: false
      t.string :jurisdiction
      t.text :clause_text, null: false
      t.boolean :required, default: false
      t.jsonb :variables, default: {}

      t.timestamps
    end

    add_index :lease_clauses, :category
    add_index :lease_clauses, :jurisdiction
    add_index :lease_clauses, [ :category, :jurisdiction ]
    add_index :lease_clauses, :required
  end
end
