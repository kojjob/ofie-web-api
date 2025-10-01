class CreateLeaseTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :lease_templates, id: :uuid do |t|
      t.string :name, null: false
      t.string :jurisdiction, null: false
      t.text :template_content
      t.jsonb :required_clauses, default: []
      t.jsonb :optional_clauses, default: []
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :lease_templates, :jurisdiction
    add_index :lease_templates, :active
    add_index :lease_templates, [ :jurisdiction, :active ]
  end
end
