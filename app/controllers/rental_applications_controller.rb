class RentalApplicationsController < ApplicationController
  before_action :authenticate_request
  before_action :set_rental_application, only: [ :show, :edit, :update, :destroy, :approve, :reject, :under_review ]
  before_action :set_property, only: [ :new, :create ]
  before_action :authorize_access, only: [ :show, :edit, :update, :destroy, :approve, :reject, :under_review ]

  # GET /rental_applications
  def index
    @rental_applications = current_user_applications
                          .includes(:property, :tenant, :reviewed_by)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(20)

    # Filter by status if provided
    @rental_applications = @rental_applications.where(status: params[:status]) if params[:status].present?

    # Statistics for dashboard
    @stats = calculate_application_stats
  end

  # GET /rental_applications/:id
  def show
    @property = @rental_application.property
    @can_manage = can_manage_application?(@rental_application)
  end

  # GET /properties/:property_id/rental_applications/new
  def new
    # Check if user already has a pending application for this property
    existing_application = current_user.rental_applications
                                      .where(property: @property)
                                      .where(status: [ "pending", "under_review" ])
                                      .first

    if existing_application
      redirect_to rental_application_path(existing_application),
                  notice: "You already have a pending application for this property."
      return
    end

    # Check if property is available for applications
    unless @property.available_for_applications?
      redirect_to property_path(@property),
                  alert: "This property is not currently accepting applications."
      return
    end

    @rental_application = @property.rental_applications.build
    @rental_application.tenant = current_user
    @rental_application.move_in_date = 1.month.from_now.to_date
  end

  # POST /properties/:property_id/rental_applications
  def create
    @rental_application = @property.rental_applications.build(rental_application_params)
    @rental_application.tenant = current_user

    respond_to do |format|
      if @rental_application.save
        # Send notification to landlord
        send_application_notification

        format.html {
          redirect_to rental_application_path(@rental_application),
          notice: "Your rental application has been submitted successfully!"
        }
        format.json {
          render json: {
            message: "Application submitted successfully",
            application: rental_application_json(@rental_application)
          }, status: :created
        }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json {
          render json: {
            errors: @rental_application.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # GET /rental_applications/:id/edit
  def edit
    unless can_edit_application?(@rental_application)
      redirect_to rental_application_path(@rental_application),
                  alert: "This application cannot be edited."
      nil
    end
  end

  # PATCH/PUT /rental_applications/:id
  def update
    unless can_edit_application?(@rental_application)
      redirect_to rental_application_path(@rental_application),
                  alert: "This application cannot be edited."
      return
    end

    respond_to do |format|
      if @rental_application.update(rental_application_params)
        # Send notification to landlord about application update
        send_application_update_notification

        format.html {
          redirect_to rental_application_path(@rental_application),
          notice: "Application updated successfully!"
        }
        format.json {
          render json: {
            message: "Application updated successfully",
            application: rental_application_json(@rental_application)
          }
        }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json {
          render json: {
            errors: @rental_application.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # DELETE /rental_applications/:id
  def destroy
    unless can_delete_application?(@rental_application)
      redirect_to rental_application_path(@rental_application),
                  alert: "This application cannot be deleted."
      return
    end

    @rental_application.update!(status: "withdrawn")

    respond_to do |format|
      format.html {
        redirect_to rental_applications_path,
        notice: "Application withdrawn successfully."
      }
      format.json {
        render json: { message: "Application withdrawn successfully" }
      }
    end
  end

  # POST /rental_applications/:id/approve
  def approve
    unless can_manage_application?(@rental_application)
      redirect_to rental_application_path(@rental_application),
                  alert: "You don't have permission to approve this application."
      return
    end

    @rental_application.reviewed_by = current_user
    @rental_application.review_notes = params[:review_notes]

    respond_to do |format|
      if @rental_application.approve!
        send_status_change_notification("approved")
        # Send email notification for important status change
        NotificationEmailJob.perform_later(
          Notification.where(
            user: @rental_application.tenant,
            notifiable: @rental_application,
            notification_type: "rental_application_status_change"
          ).last
        )

        format.html {
          redirect_to rental_application_path(@rental_application),
          notice: "Application approved successfully!"
        }
        format.json {
          render json: {
            message: "Application approved successfully",
            application: rental_application_json(@rental_application)
          }
        }
      else
        format.html {
          redirect_to rental_application_path(@rental_application),
          alert: "Failed to approve application."
        }
        format.json {
          render json: { error: "Failed to approve application" },
          status: :unprocessable_entity
        }
      end
    end
  end

  # POST /rental_applications/:id/reject
  def reject
    unless can_manage_application?(@rental_application)
      redirect_to rental_application_path(@rental_application),
                  alert: "You don't have permission to reject this application."
      return
    end

    @rental_application.reviewed_by = current_user
    @rental_application.review_notes = params[:review_notes]

    respond_to do |format|
      if @rental_application.reject!
        send_status_change_notification("rejected")
        # Send email notification for important status change
        NotificationEmailJob.perform_later(
          Notification.where(
            user: @rental_application.tenant,
            notifiable: @rental_application,
            notification_type: "rental_application_status_change"
          ).last
        )

        format.html {
          redirect_to rental_application_path(@rental_application),
          notice: "Application rejected."
        }
        format.json {
          render json: {
            message: "Application rejected",
            application: rental_application_json(@rental_application)
          }
        }
      else
        format.html {
          redirect_to rental_application_path(@rental_application),
          alert: "Failed to reject application."
        }
        format.json {
          render json: { error: "Failed to reject application" },
          status: :unprocessable_entity
        }
      end
    end
  end

  # POST /rental_applications/:id/under_review
  def under_review
    unless can_manage_application?(@rental_application)
      redirect_to rental_application_path(@rental_application),
                  alert: "You don't have permission to update this application."
      return
    end

    @rental_application.reviewed_by = current_user
    @rental_application.review_notes = params[:review_notes]

    respond_to do |format|
      if @rental_application.under_review!
        send_status_change_notification("under_review")

        format.html {
          redirect_to rental_application_path(@rental_application),
          notice: "Application marked as under review."
        }
        format.json {
          render json: {
            message: "Application marked as under review",
            application: rental_application_json(@rental_application)
          }
        }
      else
        format.html {
          redirect_to rental_application_path(@rental_application),
          alert: "Failed to update application status."
        }
        format.json {
          render json: { error: "Failed to update application status" },
          status: :unprocessable_entity
        }
      end
    end
  end

  # GET /api/v1/rental_applications/approved
  def approved_for_lease
    # Only landlords can access this endpoint
    unless current_user&.landlord?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    # Get approved applications without existing leases for current user's properties
    @approved_applications = RentalApplication.joins(:property)
                                             .includes(:property, :tenant)
                                             .where(properties: { user_id: current_user.id })
                                             .where(status: "approved")
                                             .where.missing(:lease_agreement)
                                             .order(created_at: :desc)

    render json: {
      applications: @approved_applications.map { |app| approved_application_json(app) }
    }
  end

  private

  def set_rental_application
    @rental_application = RentalApplication.find(params[:id])
  end

  def set_property
    @property = Property.find(params[:property_id]) if params[:property_id]
  end

  def authorize_access
    unless can_access_application?(@rental_application)
      redirect_to rental_applications_path, alert: "Access denied."
    end
  end

  def rental_application_params
    params.require(:rental_application).permit(
      :move_in_date, :monthly_income, :employment_status, :employer_name,
      :employment_duration, :previous_address, :previous_landlord_contact,
      :reason_for_moving, :references_contact, :additional_notes,
      :pets_description, :emergency_contact_name, :emergency_contact_phone,
      :background_check_consent, :credit_check_consent
    )
  end

  def current_user_applications
    if current_user.landlord?
      # Landlord sees applications for their properties
      RentalApplication.joins(:property).where(properties: { user_id: current_user.id })
    else
      # Tenant sees their own applications
      current_user.rental_applications
    end
  end

  def can_access_application?(application)
    return true if application.tenant == current_user
    return true if application.property.user == current_user
    false
  end

  def can_manage_application?(application)
    application.property.user == current_user
  end

  def can_edit_application?(application)
    return false unless application.tenant == current_user
    [ "pending", "under_review" ].include?(application.status)
  end

  def can_delete_application?(application)
    return false unless application.tenant == current_user
    [ "pending", "under_review" ].include?(application.status)
  end

  def calculate_application_stats
    applications = current_user_applications

    {
      total: applications.count,
      pending: applications.pending.count,
      under_review: applications.under_review.count,
      approved: applications.approved.count,
      rejected: applications.rejected.count
    }
  end

  def send_application_notification
    # Send notification to landlord about new application
    if @rental_application.property.user != current_user
      Notification.create_rental_application_notification(
        @rental_application.property.user,
        @rental_application
      )
    end
  end

  def send_status_change_notification(status)
    # Send notification to tenant about status change
    if @rental_application.tenant != current_user
      Notification.create_application_status_notification(
        @rental_application.tenant,
        @rental_application,
        status
      )
    end
  end

  def send_application_update_notification
    # Send notification to landlord about application update
    if @rental_application.property.user != current_user
      Notification.create_application_updated_notification(
        @rental_application.property.user,
        @rental_application
      )
    end
  end

  def rental_application_json(application, include_details: false)
    json = {
      id: application.id,
      status: application.status,
      application_date: application.application_date,
      move_in_date: application.move_in_date,
      monthly_income: application.monthly_income,
      employment_status: application.employment_status,
      created_at: application.created_at,
      updated_at: application.updated_at
    }

    if include_details
      json.merge!({
        employer_name: application.employer_name,
        employment_duration: application.employment_duration,
        previous_address: application.previous_address,
        previous_landlord_contact: application.previous_landlord_contact,
        reason_for_moving: application.reason_for_moving,
        references_contact: application.references_contact,
        additional_notes: application.additional_notes,
        pets_description: application.pets_description,
        emergency_contact_name: application.emergency_contact_name,
        emergency_contact_phone: application.emergency_contact_phone,
        background_check_consent: application.background_check_consent,
        credit_check_consent: application.credit_check_consent,
        review_notes: application.review_notes,
        reviewed_at: application.reviewed_at,
        reviewed_by: application.reviewed_by&.name,
        property: {
          id: application.property.id,
          title: application.property.title,
          address: application.property.address,
          rent: application.property.price
        },
        tenant: {
          id: application.tenant.id,
          name: application.tenant.name,
          email: application.tenant.email
        }
      })
    end

    json
  end

  def approved_application_json(application)
    {
      id: application.id,
      tenant_name: application.tenant.name,
      tenant_email: application.tenant.email,
      property_address: "#{application.property.address}, #{application.property.city}, #{application.property.state}",
      monthly_rent: application.property.price,
      move_in_date: application.move_in_date.strftime("%B %d, %Y"),
      application_date: application.application_date.strftime("%B %d, %Y"),
      monthly_income: application.monthly_income,
      employment_status: application.employment_status,
      property: {
        id: application.property.id,
        title: application.property.title,
        address: application.property.address,
        city: application.property.city,
        state: application.property.state,
        price: application.property.price
      },
      tenant: {
        id: application.tenant.id,
        name: application.tenant.name,
        email: application.tenant.email
      }
    }
  end
end
