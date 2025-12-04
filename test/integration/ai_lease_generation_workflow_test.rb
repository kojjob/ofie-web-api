# frozen_string_literal: true

require "test_helper"
require "llm_ruby"
require "ostruct"

class AiLeaseGenerationWorkflowTest < ActionDispatch::IntegrationTest
  # Helper method to stub LLM.from_string! for testing
  def stub_llm(mock_or_proc)
    original_method = LLM.method(:from_string!)

    if mock_or_proc.is_a?(Proc)
      LLM.define_singleton_method(:from_string!, &mock_or_proc)
    else
      LLM.define_singleton_method(:from_string!) { |_model_name| mock_or_proc }
    end

    yield
  ensure
    LLM.define_singleton_method(:from_string!, original_method)
  end
  setup do
    @landlord = create(:user, role: "landlord", name: "John Smith", email: "landlord@example.com")
    @tenant = create(:user, role: "tenant", name: "Jane Doe", email: "tenant@example.com")

    @property = create(:property,
      user: @landlord,
      title: "Test Property",
      address: "123 Main St",
      city: "San Francisco",
      bedrooms: 2,
      bathrooms: 1,
      square_feet: 850,
      price: 2500,
      property_type: "apartment"
    )

    @rental_application = create(:rental_application,
      property: @property,
      tenant: @tenant,
      status: "approved",
      move_in_date: 1.month.from_now.to_date
    )
  end

  test "complete AI lease generation workflow with successful AI generation" do
    # Mock successful AI generation
    mock_response = OpenStruct.new(
      content: "# RESIDENTIAL LEASE AGREEMENT\n\nLANDLORD: John Smith\nTENANT: Jane Doe",
      raw_response: {
        "usage" => {
          "prompt_tokens" => 500,
          "completion_tokens" => 1200,
          "total_tokens" => 1700
        }
      }
    )

    mock_client = Object.new
    mock_client.define_singleton_method(:chat) { |_messages| mock_response }
    mock_llm = OpenStruct.new(client: mock_client)

    # Use the stub_llm helper
    stub_llm(mock_llm) do
      # Step 1: Create service instance
      service = AiLeaseGeneratorService.new(@rental_application)
      assert_instance_of AiLeaseGeneratorService, service

      # Step 2: Generate lease
      lease_agreement = service.generate

      # Step 3: Verify lease was created
      assert_not_nil lease_agreement
      assert_instance_of LeaseAgreement, lease_agreement
      assert lease_agreement.persisted?

      # Step 4: Verify AI generation attributes
      assert lease_agreement.ai_generated
      assert_equal "anthropic", lease_agreement.llm_provider
      assert_equal "claude-3-sonnet-20240229", lease_agreement.llm_model

      # Step 5: Verify content
      assert_includes lease_agreement.terms_and_conditions, "RESIDENTIAL LEASE AGREEMENT"
      assert_includes lease_agreement.terms_and_conditions, "John Smith"
      assert_includes lease_agreement.terms_and_conditions, "Jane Doe"

      # Step 6: Verify metadata
      assert lease_agreement.generation_metadata.present?
      assert_equal 500, lease_agreement.generation_metadata["usage"]["prompt_tokens"]
      assert_equal 1200, lease_agreement.generation_metadata["usage"]["completion_tokens"]

      # Step 7: Verify cost calculation
      assert_operator lease_agreement.generation_cost, :>, 0

      # Step 8: Verify associations
      assert_equal @rental_application, lease_agreement.rental_application
      assert_equal @property, lease_agreement.property
      assert_equal @landlord, lease_agreement.landlord
      assert_equal @tenant, lease_agreement.tenant

      # Step 9: Verify financial terms
      assert_equal @property.price, lease_agreement.monthly_rent
      assert_equal @property.price, lease_agreement.security_deposit_amount

      # Step 10: Verify dates
      assert_equal @rental_application.move_in_date, lease_agreement.lease_start_date
      assert_equal @rental_application.move_in_date + 1.year, lease_agreement.lease_end_date
    end
  end

  test "complete workflow with AI failure falls back to template" do
    # Create template for fallback
    create(:lease_template,
      jurisdiction: "San Francisco",
      name: "San Francisco Standard Residential Lease",
      template_content: "LEASE AGREEMENT\n\nLandlord: {{landlord_name}}\nTenant: {{tenant_name}}",
      required_clauses: [],
      optional_clauses: []
    )

    # Mock AI failure
    stub_llm(->(_model_name) { raise StandardError.new("API Error") }) do
      # Step 1: Create service instance
      service = AiLeaseGeneratorService.new(@rental_application)

      # Step 2: Generate lease (should fall back to template)
      lease_agreement = service.generate

      # Step 3: Verify lease was created
      assert_not_nil lease_agreement
      assert_instance_of LeaseAgreement, lease_agreement

      # Step 4: Verify template generation attributes
      assert_not lease_agreement.ai_generated
      assert_nil lease_agreement.llm_provider
      assert_nil lease_agreement.llm_model

      # Step 5: Verify content from template
      assert_includes lease_agreement.terms_and_conditions, "LEASE AGREEMENT"
      assert_includes lease_agreement.terms_and_conditions, "John Smith"
      assert_includes lease_agreement.terms_and_conditions, "Jane Doe"

      # Step 6: Verify associations
      assert_equal @rental_application, lease_agreement.rental_application
      assert_equal @property, lease_agreement.property
    end
  end

  test "workflow fails when rental application is not approved" do
    @rental_application.update!(status: "pending")

    service = AiLeaseGeneratorService.new(@rental_application)
    result = service.generate

    assert_nil result
    assert service.errors.any?
    assert_includes service.errors.join, "must be approved"
  end

  test "workflow fails when both AI and template generation fail" do
    # Mock AI failure
    stub_llm(->(_model_name) { raise StandardError.new("API Error") }) do
      # Stub template failure
      original_method = LeaseTemplate.method(:find_for_property)
      LeaseTemplate.define_singleton_method(:find_for_property) { |_property| nil }

      begin
        service = AiLeaseGeneratorService.new(@rental_application)
        result = service.generate

        assert_nil result
        assert service.errors.any?
      ensure
        LeaseTemplate.define_singleton_method(:find_for_property, original_method)
      end
    end
  end

  test "workflow with multi-provider fallback" do
    call_count = 0

    # Mock response for OpenAI (second provider)
    mock_response = OpenStruct.new(
      content: "# LEASE AGREEMENT\n\nGenerated by OpenAI",
      raw_response: {
        "usage" => {
          "prompt_tokens" => 400,
          "completion_tokens" => 1000,
          "total_tokens" => 1400
        }
      }
    )
    mock_client = Object.new
    mock_client.define_singleton_method(:chat) { |_messages| mock_response }
    mock_llm = OpenStruct.new(client: mock_client)

    # First call (Anthropic) fails, second call (OpenAI) succeeds
    stub_llm(->(model_name) {
      call_count += 1
      if call_count == 1
        raise StandardError.new("Anthropic API Error")
      else
        mock_llm
      end
    }) do
      service = AiLeaseGeneratorService.new(@rental_application)
      lease_agreement = service.generate

      assert_not_nil lease_agreement
      assert_equal "openai", lease_agreement.llm_provider
      assert_equal "gpt-4", lease_agreement.llm_model
      assert_includes lease_agreement.terms_and_conditions, "Generated by OpenAI"
    end
  end
end
