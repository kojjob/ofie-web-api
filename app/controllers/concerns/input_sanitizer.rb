# Concern for sanitizing user input to prevent XSS and injection attacks
module InputSanitizer
  extend ActiveSupport::Concern

  included do
    before_action :sanitize_params
  end

  private

  def sanitize_params
    # Skip sanitization for certain controllers/actions
    return if skip_sanitization_for_request?

    # Get the permitted parameters based on the controller
    permitted = params.permit!

    # Sanitize the permitted parameters
    sanitize_hash!(permitted)
  end

  def sanitize_hash!(hash)
    hash.each do |key, value|
      case value
      when String
        hash[key] = sanitize_string(value) unless skip_sanitization_for_field?(key, value)
      when Hash, ActionController::Parameters
        sanitize_hash!(value)
      when Array
        value.each_with_index do |item, index|
          if item.is_a?(String)
            value[index] = sanitize_string(item) unless skip_sanitization_for_field?(key, item)
          elsif item.is_a?(Hash) || item.is_a?(ActionController::Parameters)
            sanitize_hash!(item)
          end
        end
      end
    end
  end

  def sanitize_string(string)
    return string if string.blank?

    # Remove any HTML tags and entities
    sanitized = ActionController::Base.helpers.strip_tags(string)

    # Remove any JavaScript event handlers
    sanitized = remove_javascript_handlers(sanitized)

    # Normalize whitespace
    sanitized.strip.gsub(/\s+/, " ")
  end

  def remove_javascript_handlers(string)
    # Remove common XSS patterns
    string.gsub(/javascript:/i, "")
          .gsub(/on\w+\s*=/i, "")
          .gsub(/<script.*?<\/script>/mi, "")
          .gsub(/vbscript:/i, "")
          .gsub(/data:text\/html/i, "")
  end

  def skip_sanitization_for_request?
    # Skip for certain controllers that handle their own sanitization
    excluded_controllers = %w[active_storage/blobs active_storage/representations]
    excluded_controllers.include?(controller_path)
  end

  def skip_sanitization_for_field?(key, value)
    # Skip sanitization for specific fields
    skip_fields = %w[
      password password_confirmation
      authenticity_token _method
      utf8 commit
    ]

    return true if skip_fields.include?(key.to_s)

    # Skip for specific controller/action/field combinations
    if controller_name == "properties" && action_name.in?(%w[create update])
      # Allow HTML in property descriptions
      return true if key.to_s == "description"
    end

    false
  end

  # Additional helper methods for specific sanitization needs

  def sanitize_filename(filename)
    return nil if filename.blank?
    # Remove any path traversal attempts
    filename.gsub(/[\/\\]/, "").gsub(/\.{2,}/, ".")
  end

  def sanitize_url(url)
    return nil if url.blank?

    # Parse and validate URL
    uri = URI.parse(url)

    # Only allow http(s) and ensure it's a valid URL
    if uri.scheme.in?(%w[http https]) && uri.host.present?
      url
    else
      nil
    end
  rescue URI::InvalidURIError
    nil
  end

  def sanitize_email(email)
    return nil if email.blank?

    # Basic email validation and normalization
    email = email.strip.downcase

    if email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      email
    else
      nil
    end
  end

  def sanitize_phone(phone)
    return nil if phone.blank?

    # Remove all non-numeric characters except + for international
    phone.gsub(/[^\d+]/, "")
  end

  # Numeric sanitization helpers

  def sanitize_integer(value)
    Integer(value) rescue nil
  end

  def sanitize_float(value)
    Float(value) rescue nil
  end

  def sanitize_price(value)
    return nil if value.blank?

    # Remove currency symbols and convert to float
    cleaned = value.to_s.gsub(/[$,]/, "")
    Float(cleaned) rescue nil
  end
end
