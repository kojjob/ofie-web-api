module Properties
  class CreateService < ApplicationService
    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      return failure("User must be a landlord") unless @user.landlord?
      
      with_transaction do
        property = build_property
        
        if property.save
          attach_images(property) if @params[:images].present?
          notify_subscribers(property)
          schedule_indexing(property)
          
          log_execution("Property created: #{property.id}")
          success(property: property)
        else
          failure(property.errors.full_messages)
        end
      end
    end

    private

    attr_reader :user, :params

    def build_property
      user.properties.build(property_params)
    end

    def property_params
      params.except(:images).merge(
        status: params[:status] || 'available',
        listed_at: Time.current
      )
    end

    def attach_images(property)
      params[:images].each do |image|
        property.images.attach(image)
      end
    rescue StandardError => e
      log_execution("Failed to attach images: #{e.message}", :error)
    end

    def notify_subscribers(property)
      # Send notifications to users who have saved searches matching this property
      NotificationJob.perform_later(
        type: 'new_property',
        property_id: property.id,
        location: property.location
      )
    rescue StandardError => e
      log_execution("Failed to send notifications: #{e.message}", :warn)
    end

    def schedule_indexing(property)
      # Schedule background job to index property for search
      PropertyIndexJob.perform_later(property.id)
    rescue StandardError => e
      log_execution("Failed to schedule indexing: #{e.message}", :warn)
    end
  end
end