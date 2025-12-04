class AddAiFieldsToLeaseAgreements < ActiveRecord::Migration[8.0]
  def change
    add_column :lease_agreements, :ai_generated, :boolean, default: false
    add_column :lease_agreements, :llm_provider, :string
    add_column :lease_agreements, :llm_model, :string
    add_column :lease_agreements, :generation_metadata, :jsonb, default: {}
    add_column :lease_agreements, :generation_cost, :decimal, precision: 10, scale: 4
    add_column :lease_agreements, :reviewed_by_landlord, :boolean, default: false
    add_column :lease_agreements, :landlord_review_notes, :text

    add_index :lease_agreements, :ai_generated
    add_index :lease_agreements, :llm_provider
    add_index :lease_agreements, :reviewed_by_landlord
  end
end
