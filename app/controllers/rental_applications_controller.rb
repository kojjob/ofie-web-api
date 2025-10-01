class RentalApplicationsController < ApplicationController
  before_action :authenticate_request
  before_action :set_rental_application, only: [ :show, :edit, :update, :destroy, :approve, :reject, :under_review, :generate_lease ]
  before_action :set_property, only: [ :new, :create ]
  before_action :authorize_access, only: [ :show, :edit, :update, :destroy, :approve, :reject, :under_review ]
  before_action :authorize_lease_generation, only: [ :generate_lease ]

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
    existing_application = current_user.tenant_rental_applications
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

  # POST /rental_applications/:id/generate_lease
  def generate_lease
    # Check if lease already exists
    if @rental_application.lease_agreement.present?
      respond_to do |format|
        format.html {
          redirect_to rental_application_path(@rental_application),
          alert: "A lease agreement already exists for this application."
        }
        format.json {
          render json: {
            error: "Lease already exists",
            lease_agreement_id: @rental_application.lease_agreement.id
          }, status: :unprocessable_entity
        }
      end
      return
    end

    # Generate lease using AI service
    generator = AiLeaseGeneratorService.new(@rental_application)
    lease_agreement = generator.generate

    respond_to do |format|
      if lease_agreement
        send_lease_generated_notification(lease_agreement)

        format.html {
          redirect_to edit_lease_agreement_path(lease_agreement),
          notice: "Lease agreement generated successfully! Please review and customize as needed."
        }
        format.json {
          render json: {
            message: "Lease agreement generated successfully",
            lease_agreement: lease_agreement_json(lease_agreement)
          }, status: :created
        }
      else
        format.html {
          redirect_to rental_application_path(@rental_application),
          alert: "Failed to generate lease agreement: #{generator.errors.join(', ')}"
        }
        format.json {
          render json: {
            error: "Lease generation failed",
            details: generator.errors
          }, status: :unprocessable_entity
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
                                             .where(status: 'approved')
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
      :move_in_date, :monthly_income, :employment_status,
      :previous_address, :references_contact, :additional_notes,
      :credit_score
    )
  end

  def current_user_applications
    if current_user.landlord?
      # Landlord sees applications for their properties
      RentalApplication.joins(:property).where(properties: { user_id: current_user.id })
    else
      # Tenant sees their own applications
      current_user.tenant_rental_applications
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
        previous_address: application.previous_address,
        references_contact: application.references_contact,
        additional_notes: application.additional_notes,
        credit_score: application.credit_score,
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

  def authorize_lease_generation
    unless can_manage_application?(@rental_application)
      respond_to do |format|
        format.html {
          redirect_to rental_application_path(@rental_application),
          alert: "You don't have permission to generate a lease for this application."
        }
        format.json {
          render json: { error: "Unauthorized" }, status: :unauthorized
        }
      end
      return
    end

    unless @rental_application.approved?
      respond_to do |format|
        format.html {
          redirect_to rental_application_path(@rental_application),
          alert: "Application must be approved before generating a lease."
        }
        format.json {
          render json: { error: "Application must be approved" }, status: :unprocessable_entity
        }
      end
    end
  end

  def send_lease_generated_notification(lease_agreement)
    # Send notification to tenant about lease generation
    if @rental_application.tenant != current_user
      Notification.create!(
        user: @rental_application.tenant,
        notifiable: lease_agreement,
        notification_type: "lease_generated",
        message: "A lease agreement has been generated for your rental application.",
        data: {
          application_id: @rental_application.id,
          property_address: @rental_application.property.full_address,
          ai_generated: lease_agreement.ai_generated
        }
      )
    end
  end

  def lease_agreement_json(lease_agreement)
    {
      id: lease_agreement.id,
      status: lease_agreement.status,
      lease_start_date: lease_agreement.lease_start_date,
      lease_end_date: lease_agreement.lease_end_date,
      monthly_rent: lease_agreement.monthly_rent,
      security_deposit_amount: lease_agreement.security_deposit_amount,
      ai_generated: lease_agreement.ai_generated,
      llm_provider: lease_agreement.llm_provider,
      llm_model: lease_agreement.llm_model,
      generation_cost: lease_agreement.generation_cost,
      reviewed_by_landlord: lease_agreement.reviewed_by_landlord,
      created_at: lease_agreement.created_at,
      rental_application: {
        id: @rental_application.id,
        status: @rental_application.status
      },
      property: {
        id: lease_agreement.property.id,
        address: lease_agreement.property.full_address
      },
      tenant: {
        id: lease_agreement.tenant.id,
        name: lease_agreement.tenant.full_name,
        email: lease_agreement.tenant.email
      },
      landlord: {
        id: lease_agreement.landlord.id,
        name: lease_agreement.landlord.full_name,
        email: lease_agreement.landlord.email
      }
    }
  end
end
