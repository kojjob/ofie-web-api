# frozen_string_literal: true

# Service for generating lease agreements from templates
# Used as fallback when AI generation fails
class LeaseTemplateService
  attr_reader :lease_agreement, :errors

  def initialize(lease_agreement)
    @lease_agreement = lease_agreement
    @errors = []
  end

  # Generate lease content from template
  # Returns: String with lease content or nil on failure
  def generate
    template = find_appropriate_template
    return nil unless template

    content = render_template(template)
    return nil unless content

    content
  rescue StandardError => e
    Rails.logger.error("[LeaseTemplateService] Error: #{e.message}")
    @errors << "Template generation failed: #{e.message}"
    nil
  end

  private

  def find_appropriate_template
    jurisdiction = lease_agreement.property.state || lease_agreement.property.city

    template = LeaseTemplate.find_for_property(lease_agreement.property)

    unless template
      @errors << "No lease template found for jurisdiction: #{jurisdiction}"
      Rails.logger.error("[LeaseTemplateService] No template found for #{jurisdiction}")
    end

    template
  end

  def render_template(template)
    content = template.template_content.dup

    # Replace variables with actual values
    variables = build_template_variables
    variables.each do |key, value|
      content.gsub!("{{#{key}}}", value.to_s)
    end

    # Add required clauses
    content += "\n\n" + render_clauses(template.required_clauses, required: true)

    # Add optional clauses
    content += "\n\n" + render_clauses(template.optional_clauses, required: false)

    content
  end

  def build_template_variables
    {
      # Property information
      property_address: lease_agreement.property.full_address,
      property_type: lease_agreement.property.property_type,
      bedrooms: lease_agreement.property.bedrooms,
      bathrooms: lease_agreement.property.bathrooms,
      square_feet: lease_agreement.property.square_feet || "N/A",

      # Landlord information
      landlord_name: lease_agreement.landlord.full_name,
      landlord_email: lease_agreement.landlord.email,
      landlord_phone: lease_agreement.landlord.phone_number || "N/A",

      # Tenant information
      tenant_name: lease_agreement.tenant.full_name,
      tenant_email: lease_agreement.tenant.email,
      tenant_phone: lease_agreement.tenant.phone_number || "N/A",

      # Lease terms
      lease_start_date: lease_agreement.lease_start_date.strftime("%B %d, %Y"),
      lease_end_date: lease_agreement.lease_end_date.strftime("%B %d, %Y"),
      monthly_rent: format_currency(lease_agreement.monthly_rent),
      security_deposit: format_currency(lease_agreement.security_deposit_amount),

      # Additional details
      pets_allowed: lease_agreement.property.pets_allowed? ? "Yes" : "No",
      parking_spaces: lease_agreement.property.parking_spaces || 0,
      furnished: lease_agreement.property.furnished? ? "Yes" : "No"
    }
  end

  def render_clauses(clause_ids, required: false)
    return "" if clause_ids.blank?

    jurisdiction = lease_agreement.property.state || lease_agreement.property.city
    rendered_clauses = []

    clause_ids.each do |clause_id|
      clause = LeaseClause.find_by(id: clause_id)
      next unless clause

      # Replace variables in clause text
      clause_text = clause.replace_variables(build_template_variables)

      rendered_clauses << "## #{clause.category.titleize}\n\n#{clause_text}"
    end

    rendered_clauses.join("\n\n")
  end

  def format_currency(amount)
    "$#{format('%.2f', amount)}"
  end
end
