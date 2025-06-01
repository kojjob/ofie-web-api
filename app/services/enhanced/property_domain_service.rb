# Enhanced Property Domain Service following DDD principles
# Handles complex property-related business logic with clear separation of concerns
class PropertyDomainService
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  class PropertyCreationResult
    attr_reader :property, :success, :errors

    def initialize(property:, success:, errors: [])
      @property = property
      @success = success
      @errors = errors
    end

    def success?
      @success
    end

    def failure?
      !success?
    end
  end

  class << self
    # Create property with comprehensive validation and business rules
    def create_property(landlord:, property_params:)
      return failure_result("Landlord must be present") unless landlord&.landlord?

      # Apply business rules before creation
      enhanced_params = apply_creation_business_rules(property_params, landlord)

      property = Property.new(enhanced_params.merge(user: landlord))

      Property.transaction do
        if property.save
          post_creation_actions(property)
          PropertyCreationResult.new(property: property, success: true)
        else
          PropertyCreationResult.new(
            property: property,
            success: false,
            errors: property.errors.full_messages
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error "Property creation failed: #{e.message}"
      failure_result("Property creation failed: #{e.message}")
    end

    # Update property availability based on lease status
    def update_availability_status(property)
      return unless property.persisted?

      new_status = calculate_availability_status(property)

      if property.availability_status != new_status
        property.update!(availability_status: new_status)
        PropertyAvailabilityChangedEvent.trigger(property, property.availability_status_was, new_status)
      end
    end

    # Archive property with proper validation
    def archive_property(property, reason: nil)
      return failure_result("Cannot archive property with active leases") if has_active_leases?(property)

      Property.transaction do
        property.update!(
          status: :archived,
          archived_at: Time.current,
          archive_reason: reason
        )

        # Cancel pending applications
        property.rental_applications.pending.each(&:withdraw!)

        # Notify interested parties
        NotificationService.notify_property_archived(property)

        success_result(property)
      end
    rescue StandardError => e
      failure_result("Archive failed: #{e.message}")
    end

    # Calculate property score for ranking/recommendation
    def calculate_property_score(property)
      base_score = 50

      # Location score (would integrate with external APIs)
      location_score = calculate_location_score(property)

      # Property features score
      features_score = calculate_features_score(property)

      # Reviews and ratings score
      reviews_score = calculate_reviews_score(property)

      # Pricing competitiveness
      pricing_score = calculate_pricing_score(property)

      # Recent activity score
      activity_score = calculate_activity_score(property)

      total_score = [
        base_score + location_score + features_score +
        reviews_score + pricing_score + activity_score,
        100
      ].min

      property.update_column(:score, total_score)
      total_score
    end

    # Property search with enhanced filtering
    def search_properties(search_params = {})
      PropertySearchService.new(search_params).call
    end

    # Validate property readiness for applications
    def validate_application_readiness(property)
      validation_errors = []

      validation_errors << "Property must be active" unless property.status_active?
      validation_errors << "Property must be available" unless property.available?
      validation_errors << "Property must have photos" unless property.photos.any?
      validation_errors << "Property description required" if property.description.blank?
      validation_errors << "Property must have valid pricing" unless property.price&.positive?

      {
        ready: validation_errors.empty?,
        errors: validation_errors
      }
    end

    private

    def apply_creation_business_rules(params, landlord)
      enhanced_params = params.dup

      # Set default values based on business rules
      enhanced_params[:status] ||= :draft
      enhanced_params[:availability_status] ||= :available
      enhanced_params[:listing_date] ||= Date.current

      # Apply landlord-specific defaults
      if landlord.properties.count.zero?
        enhanced_params[:featured] = true # First property gets featured
      end

      enhanced_params
    end

    def post_creation_actions(property)
      # Send welcome email for first property
      if property.user.properties.count == 1
        LandlordMailer.first_property_created(property.user).deliver_later
      end

      # Index for search
      PropertyIndexJob.perform_later(property.id)

      # Calculate initial score
      PropertyScoreJob.perform_later(property.id)
    end

    def calculate_availability_status(property)
      return :maintenance if property.maintenance_requests.in_progress.any?
      return :rented if has_active_leases?(property)
      return :pending if property.rental_applications.under_review.any?

      :available
    end

    def has_active_leases?(property)
      property.lease_agreements.active.exists?
    end

    def calculate_location_score(property)
      # Placeholder for location-based scoring
      # Would integrate with external APIs for neighborhood data
      10
    end

    def calculate_features_score(property)
      score = 0
      score += 5 if property.parking_available?
      score += 3 if property.pets_allowed?
      score += 4 if property.furnished?
      score += 3 if property.utilities_included?
      score += 2 if property.laundry?
      score
    end

    def calculate_reviews_score(property)
      return 0 if property.reviews_count.zero?

      avg_rating = property.average_rating
      review_count_multiplier = [ property.reviews_count / 5, 3 ].min

      (avg_rating * 2 * review_count_multiplier).round
    end

    def calculate_pricing_score(property)
      # Compare with similar properties in area
      # Higher score for competitive pricing
      # Placeholder implementation
      5
    end

    def calculate_activity_score(property)
      recent_activity = property.property_viewings.where(created_at: 1.month.ago..).count
      [ recent_activity, 10 ].min
    end

    def success_result(property)
      PropertyCreationResult.new(property: property, success: true)
    end

    def failure_result(error_message)
      PropertyCreationResult.new(property: nil, success: false, errors: [ error_message ])
    end
  end
end
