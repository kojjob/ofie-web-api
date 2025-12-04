# frozen_string_literal: true

require "test_helper"

class LeaseTemplateServiceTest < ActiveSupport::TestCase
  setup do
    @landlord = create(:user, role: "landlord", name: "John Smith", email: "john@example.com", phone: "+14155550100")
    @tenant = create(:user, role: "tenant", name: "Jane Doe", email: "jane@example.com", phone: "+14155550200")

    @property = create(:property,
      user: @landlord,
      title: "123 Main St, Apartment 4B",
      address: "123 Main St",
      city: "San Francisco",
      bedrooms: 2,
      bathrooms: 1,
      square_feet: 850,
      price: 2500,
      property_type: "apartment",
      pets_allowed: true,
      parking_available: true,
      furnished: false
    )

    @rental_application = create(:rental_application,
      property: @property,
      tenant: @tenant,
      status: "approved",
      move_in_date: 1.month.from_now.to_date
    )

    @lease_agreement = create(:lease_agreement,
      rental_application: @rental_application,
      property: @property,
      tenant: @tenant,
      landlord: @landlord,
      lease_start_date: 1.month.from_now.to_date,
      lease_end_date: 13.months.from_now.to_date,
      monthly_rent: @property.price,
      security_deposit_amount: @property.price
    )

    @template = create(:lease_template,
      jurisdiction: "San Francisco",
      name: "San Francisco Standard Residential Lease",
      template_content: <<~TEMPLATE,
        # RESIDENTIAL LEASE AGREEMENT

        ## PARTIES
        This Lease Agreement is made on #{Date.current.strftime("%B %d, %Y")} between:

        LANDLORD: {{landlord_name}}
        Email: {{landlord_email}}
        Phone: {{landlord_phone}}

        TENANT: {{tenant_name}}
        Email: {{tenant_email}}
        Phone: {{tenant_phone}}

        ## PROPERTY DESCRIPTION
        Address: {{property_address}}
        Type: {{property_type}}
        Bedrooms: {{bedrooms}}
        Bathrooms: {{bathrooms}}
        Square Feet: {{square_feet}}

        ## LEASE TERMS
        Lease Start Date: {{lease_start_date}}
        Lease End Date: {{lease_end_date}}
        Monthly Rent: {{monthly_rent}}
        Security Deposit: {{security_deposit}}

        ## PROPERTY FEATURES
        Pets Allowed: {{pets_allowed}}
        Parking Available: {{parking_available}}
        Furnished: {{furnished}}
      TEMPLATE
      required_clauses: [],
      optional_clauses: []
    )

    @service = LeaseTemplateService.new(@lease_agreement)
  end

  test "initializes with lease agreement data" do
    assert_equal @lease_agreement, @service.instance_variable_get(:@lease_agreement)
    assert_empty @service.errors
  end

  test "generates lease content from template" do
    result = @service.generate

    assert_kind_of String, result
    assert_includes result, "RESIDENTIAL LEASE AGREEMENT"
    assert_includes result, "John Smith"
    assert_includes result, "Jane Doe"
    assert_includes result, "123 Main St"
    assert_includes result, "San Francisco"
  end

  test "replaces all template variables" do
    result = @service.generate

    assert_includes result, "john@example.com"
    assert_includes result, "jane@example.com"
    assert_includes result, "+14155550100"
    assert_includes result, "+14155550200"
    assert_includes result, "2 bedrooms"
    assert_includes result, "1 bathrooms"
    assert_includes result, "850 square feet"
  end

  test "includes financial information" do
    result = @service.generate

    assert_includes result, "$2500.00"  # Monthly rent
    assert_includes result, 1.month.from_now.to_date.strftime("%B %d, %Y")
    assert_includes result, 13.months.from_now.to_date.strftime("%B %d, %Y")
  end

  test "handles null/missing values gracefully" do
    @property.update!(square_feet: nil)
    @lease_agreement.property.reload

    result = @service.generate

    assert_includes result, "N/A"  # Default for missing square_feet
  end

  test "formats boolean values correctly" do
    result = @service.generate

    assert_includes result, "Pets Allowed: Yes"
    assert_includes result, "Furnished: No"
  end

  test "returns nil when no template exists for jurisdiction" do
    @template.destroy

    result = @service.generate

    assert_nil result
    assert @service.errors.any? { |error| error.include?("No lease template found") }
  end

  test "includes required clauses in generated content" do
    rent_clause = create(:lease_clause,
      category: "rent_payment",
      jurisdiction: "San Francisco",
      clause_text: "Tenant shall pay rent of {{monthly_rent}} on the first day of each month.",
      required: true,
      variables: { "monthly_rent" => "Monthly Rent Amount" }
    )
    @template.update!(required_clauses: [rent_clause.id])

    result = @service.generate

    assert_includes result, "Rent Payment"
    assert_includes result, "Tenant shall pay rent of $2500.00"
  end

  test "includes optional clauses in generated content" do
    pet_clause = create(:lease_clause,
      category: "pets",
      jurisdiction: "San Francisco",
      clause_text: "Pets are allowed with a non-refundable pet deposit.",
      required: false
    )
    @template.update!(optional_clauses: [pet_clause.id])

    result = @service.generate

    assert_includes result, "Pets"
    assert_includes result, "Pets are allowed with a non-refundable pet deposit"
  end

  test "builds complete variable hash" do
    variables = @service.send(:build_template_variables)

    assert_equal @property.full_address, variables[:property_address]
    assert_equal "John Smith", variables[:landlord_name]
    assert_equal "Jane Doe", variables[:tenant_name]
    assert_equal "$2500.00", variables[:monthly_rent]
  end

  test "handles missing phone numbers" do
    @landlord.update!(phone: nil)
    variables = @service.send(:build_template_variables)

    assert_equal "N/A", variables[:landlord_phone]
  end

  test "formats currency correctly" do
    variables = @service.send(:build_template_variables)

    assert_match(/\$\d+\.\d{2}/, variables[:monthly_rent])
    assert_match(/\$\d+\.\d{2}/, variables[:security_deposit])
  end

  test "formats dates in human-readable format" do
    variables = @service.send(:build_template_variables)

    assert_match(/\w+ \d{1,2}, \d{4}/, variables[:lease_start_date])
    assert_match(/\w+ \d{1,2}, \d{4}/, variables[:lease_end_date])
  end

  test "renders required clauses with proper formatting" do
    rent_clause = create(:lease_clause,
      category: "rent_payment",
      jurisdiction: "San Francisco",
      clause_text: "Tenant shall pay rent on time.",
      required: true
    )
    maintenance_clause = create(:lease_clause,
      category: "maintenance",
      jurisdiction: "San Francisco",
      clause_text: "Tenant is responsible for routine maintenance.",
      required: true
    )

    clause_ids = [rent_clause.id, maintenance_clause.id]
    result = @service.send(:render_clauses, clause_ids, required: true)

    assert_includes result, "## Rent Payment"
    assert_includes result, "## Maintenance"
    assert_includes result, "Tenant shall pay rent"
    assert_includes result, "Tenant is responsible for routine maintenance"
  end

  test "renders optional clauses" do
    utilities_clause = create(:lease_clause,
      category: "utilities",
      jurisdiction: "San Francisco",
      clause_text: "Tenant pays for electricity and gas.",
      required: false
    )

    clause_ids = [utilities_clause.id]
    result = @service.send(:render_clauses, clause_ids, required: false)

    assert_includes result, "## Utilities"
    assert_includes result, "Tenant pays for electricity"
  end

  test "returns empty string for blank clause IDs" do
    result = @service.send(:render_clauses, [], required: true)
    assert_equal "", result
  end

  test "replaces variables in clause text" do
    clause_with_var = create(:lease_clause,
      category: "late_fees",
      jurisdiction: "San Francisco",
      clause_text: "Late fee of 5% of {{monthly_rent}} applies after 5 days.",
      required: true,
      variables: { "monthly_rent" => "Monthly Rent Amount" }
    )

    result = @service.send(:render_clauses, [clause_with_var.id], required: true)

    assert_includes result, "Late fee of 5% of $2500.00"
  end

  test "formats currency with 2 decimal places" do
    result = @service.send(:format_currency, 2500)
    assert_equal "$2500.00", result
  end

  test "handles decimal amounts" do
    result = @service.send(:format_currency, 2500.50)
    assert_equal "$2500.50", result
  end

  test "handles large amounts" do
    result = @service.send(:format_currency, 10_000)
    assert_equal "$10000.00", result
  end

  test "handles missing clauses gracefully" do
    @template.update!(required_clauses: ["non-existent-uuid"])

    result = @service.generate

    assert_kind_of String, result
    # Should still generate template content even if clauses are missing
    assert_includes result, "RESIDENTIAL LEASE AGREEMENT"
  end
end
