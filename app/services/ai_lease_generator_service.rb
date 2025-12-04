# frozen_string_literal: true

# Service for generating lease agreements using AI (OpenAI, Anthropic Claude, Google Gemini)
# Uses llm_ruby gem for multi-provider support with automatic fallback
class AiLeaseGeneratorService
  attr_reader :rental_application, :property, :landlord, :tenant, :errors

  # Initialize with a rental application that has been approved
  def initialize(rental_application)
    @rental_application = rental_application
    @property = rental_application.property
    @landlord = rental_application.landlord
    @tenant = rental_application.tenant
    @errors = []
  end

  # Main entry point: Generate lease agreement with AI
  # Returns: LeaseAgreement object or nil on failure
  def generate
    validate_prerequisites
    return nil if @errors.any?

    lease_agreement = create_lease_agreement_record
    return nil unless lease_agreement

    # Try AI generation with provider fallback
    success = try_ai_generation(lease_agreement)

    if success
      lease_agreement.reload
    else
      # Fall back to template-based generation
      fallback_to_template(lease_agreement)
    end

    lease_agreement
  rescue StandardError => e
    Rails.logger.error("[AiLeaseGeneratorService] Unexpected error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    @errors << "Unexpected error during lease generation: #{e.message}"
    nil
  end

  private

  # Validate that all required data is present
  def validate_prerequisites
    @errors << "Rental application must be approved" unless @rental_application.approved?
    @errors << "Property is required" unless @property
    @errors << "Landlord is required" unless @landlord
    @errors << "Tenant is required" unless @tenant
    @errors << "Property must have location information" unless property_has_location?
  end

  def property_has_location?
    @property.address.present? && @property.city.present?
  end

  # Create initial lease agreement record
  def create_lease_agreement_record
    LeaseAgreement.create!(
      rental_application: @rental_application,
      property: @property,
      landlord: @landlord,
      tenant: @tenant,
      status: "draft",
      lease_start_date: @rental_application.move_in_date || 30.days.from_now,
      lease_end_date: calculate_lease_end_date,
      monthly_rent: @property.price,
      security_deposit_amount: calculate_security_deposit,
      ai_generated: true,
      reviewed_by_landlord: false
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[AiLeaseGeneratorService] Failed to create lease agreement: #{e.message}")
    @errors << "Failed to create lease agreement: #{e.message}"
    nil
  end

  def calculate_lease_end_date
    start_date = @rental_application.move_in_date || 30.days.from_now
    lease_duration = 12 # Default to 12 months lease
    start_date + lease_duration.months
  end

  def calculate_security_deposit
    @property.price # Default to one month's rent
  end

  # Try to generate lease using AI with provider fallback
  def try_ai_generation(lease_agreement)
    providers = %w[anthropic openai google]

    providers.each do |provider|
      begin
        Rails.logger.info("[AiLeaseGeneratorService] Attempting generation with #{provider}")
        result = generate_with_provider(lease_agreement, provider)

        if result[:success]
          update_lease_with_ai_content(lease_agreement, result, provider)
          return true
        end
      rescue StandardError => e
        Rails.logger.warn("[AiLeaseGeneratorService] #{provider} failed: #{e.message}")
        next # Try next provider
      end
    end

    Rails.logger.error("[AiLeaseGeneratorService] All AI providers failed")
    false
  end

  # Generate lease content using specific LLM provider
  def generate_with_provider(lease_agreement, provider)
    prompt = build_lease_generation_prompt(lease_agreement)

    response = LlmRuby::Client.new(provider: provider).chat(
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: prompt }
      ],
      temperature: 0.3, # Lower temperature for more consistent legal text
      max_tokens: 4000
    )

    {
      success: true,
      content: response["choices"][0]["message"]["content"],
      model: response["model"],
      usage: response["usage"],
      cost: calculate_cost(response["usage"], provider)
    }
  rescue StandardError => e
    Rails.logger.error("[AiLeaseGeneratorService] Provider #{provider} error: #{e.message}")
    { success: false, error: e.message }
  end

  # System prompt for AI lease generation
  def system_prompt
    <<~PROMPT
      You are a legal assistant specialized in creating residential lease agreements.
      Your task is to generate a comprehensive, legally compliant lease agreement based on the provided information.

      Requirements:
      - Use clear, unambiguous legal language
      - Include all standard lease clauses (rent, security deposit, maintenance, termination, etc.)
      - Adapt clauses based on jurisdiction
      - Format the lease in a professional, easy-to-read structure
      - Include sections with clear headings
      - Be specific about dates, amounts, and responsibilities

      Return ONLY the lease agreement text in markdown format.
      Do not include any preamble or explanation.
    PROMPT
  end

  # Build the user prompt with all lease details
  def build_lease_generation_prompt(lease_agreement)
    <<~PROMPT
      Generate a residential lease agreement with the following details:

      PROPERTY INFORMATION:
      - Address: #{@property.full_address}
      - Type: #{@property.property_type}
      - Bedrooms: #{@property.bedrooms}
      - Bathrooms: #{@property.bathrooms}
      - Square Feet: #{@property.square_feet}
      - Furnished: #{@property.furnished? ? 'Yes' : 'No'}
      - Parking: #{@property.parking_spaces} space(s)

      LANDLORD INFORMATION:
      - Name: #{@landlord.full_name}
      - Email: #{@landlord.email}
      - Phone: #{@landlord.phone_number}

      TENANT INFORMATION:
      - Name: #{@tenant.full_name}
      - Email: #{@tenant.email}
      - Phone: #{@tenant.phone_number}

      LEASE TERMS:
      - Start Date: #{lease_agreement.lease_start_date.strftime('%B %d, %Y')}
      - End Date: #{lease_agreement.lease_end_date.strftime('%B %d, %Y')}
      - Monthly Rent: $#{lease_agreement.monthly_rent}
      - Security Deposit: $#{lease_agreement.security_deposit_amount}
      - Jurisdiction: #{@property.city}

      ADDITIONAL DETAILS:
      #{additional_property_details}

      Please generate a complete lease agreement that includes:
      1. Parties and Property Description
      2. Lease Term and Rent
      3. Security Deposit
      4. Use of Premises
      5. Utilities and Services
      6. Maintenance and Repairs
      7. Property Condition
      8. Pets Policy
      9. Subletting and Assignment
      10. Entry and Inspection
      11. Termination and Renewal
      12. Late Fees and Default
      13. Legal Notices
      14. Additional Provisions
      15. Signatures
    PROMPT
  end

  def additional_property_details
    details = []
    details << "- Pets Allowed: #{@property.pets_allowed? ? 'Yes' : 'No'}"
    details << "- Utilities Included: #{@property.utilities_included? ? 'Yes' : 'No'}"
    details << "- Additional Notes: #{@property.description}" if @property.description.present?
    details.join("\n")
  end

  # Update lease agreement with AI-generated content
  def update_lease_with_ai_content(lease_agreement, result, provider)
    lease_agreement.update!(
      lease_terms: result[:content],
      llm_provider: provider,
      llm_model: result[:model],
      generation_metadata: {
        provider: provider,
        model: result[:model],
        usage: result[:usage],
        generated_at: Time.current.iso8601,
        prompt_tokens: result[:usage]["prompt_tokens"],
        completion_tokens: result[:usage]["completion_tokens"],
        total_tokens: result[:usage]["total_tokens"]
      },
      generation_cost: result[:cost]
    )

    Rails.logger.info("[AiLeaseGeneratorService] Successfully generated lease with #{provider}")
  end

  # Calculate approximate cost based on usage and provider
  def calculate_cost(usage, provider)
    prompt_tokens = usage["prompt_tokens"] || 0
    completion_tokens = usage["completion_tokens"] || 0

    # Approximate pricing (as of 2024, in USD per 1K tokens)
    pricing = {
      "anthropic" => { prompt: 0.003, completion: 0.015 }, # Claude 3 Sonnet
      "openai" => { prompt: 0.0015, completion: 0.002 },   # GPT-3.5 Turbo
      "google" => { prompt: 0.00025, completion: 0.0005 }  # Gemini Pro
    }

    rates = pricing[provider] || { prompt: 0.001, completion: 0.002 }

    prompt_cost = (prompt_tokens / 1000.0) * rates[:prompt]
    completion_cost = (completion_tokens / 1000.0) * rates[:completion]

    (prompt_cost + completion_cost).round(4)
  end

  # Fallback to template-based generation if AI fails
  def fallback_to_template(lease_agreement)
    Rails.logger.info("[AiLeaseGeneratorService] Falling back to template generation")

    service = LeaseTemplateService.new(lease_agreement)
    template_content = service.generate

    if template_content
      lease_agreement.update!(
        lease_terms: template_content,
        ai_generated: false,
        llm_provider: nil,
        llm_model: nil
      )
      Rails.logger.info("[AiLeaseGeneratorService] Successfully generated lease from template")
    else
      Rails.logger.error("[AiLeaseGeneratorService] Template generation also failed")
      @errors.concat(service.errors)
    end
  end
end
