FactoryBot.define do
  factory :lease_template do
    jurisdiction { "San Francisco" }
    name { "Standard Residential Lease Agreement" }
    template_content { "# LEASE AGREEMENT\n\nProperty: {{property_address}}\nLandlord: {{landlord_name}}\nTenant: {{tenant_name}}" }
    required_clauses { [] }
    optional_clauses { [] }
    active { true }
  end
end
