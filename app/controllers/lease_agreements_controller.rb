class LeaseAgreementsController < ApplicationController
  before_action :authenticate_request
  before_action :set_lease_agreement, only: [:show, :edit, :update, :destroy, :sign_tenant, :sign_landlord, :activate, :terminate]
  before_action :authorize_access, only: [:show, :edit, :update, :destroy, :sign_tenant, :sign_landlord, :activate, :terminate]

  # GET /lease_agreements
  def index
    @lease_agreements = current_user_leases
                       .includes(:property, :tenant, :landlord, :rental_application)
                       .order(created_at: :desc)
                       .page(params[:page])
                       .per(20)
    
    # Filter by status if provided
    @lease_agreements = @lease_agreements.where(status: params[:status]) if params[:status].present?
    
    # Statistics for dashboard
    @stats = calculate_lease_stats
  end

  # GET /lease_agreements/:id
  def show
    @property = @lease_agreement.property
    @can_manage = can_manage_lease?(@lease_agreement)
    @can_sign = can_sign_lease?(@lease_agreement)
  end

  # GET /rental_applications/:rental_application_id/lease_agreements/new
  def new
    @rental_application = RentalApplication.find(params[:rental_application_id])
    
    # Check if user can create lease for this application
    unless can_create_lease_for_application?(@rental_application)
      redirect_to rental_application_path(@rental_application), 
                  alert: "You don't have permission to create a lease for this application."
      return
    end
    
    # Check if lease already exists
    if @rental_application.lease_agreement.present?
      redirect_to lease_agreement_path(@rental_application.lease_agreement), 
                  notice: "Lease agreement already exists for this application."
      return
    end
    
    @lease_agreement = build_lease_from_application(@rental_application)
    @property = @rental_application.property
  end

  # POST /rental_applications/:rental_application_id/lease_agreements
  def create
    @rental_application = RentalApplication.find(params[:rental_application_id])
    
    unless can_create_lease_for_application?(@rental_application)
      redirect_to rental_application_path(@rental_application), 
                  alert: "You don't have permission to create a lease for this application."
      return
    end
    
    @lease_agreement = build_lease_from_application(@rental_application)
    @lease_agreement.assign_attributes(lease_agreement_params)
    
    respond_to do |format|
      if @lease_agreement.save
        # Send notification to tenant about new lease
        send_lease_created_notification
        
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          notice: "Lease agreement created successfully! The tenant has been notified." 
        }
        format.json { 
          render json: { 
            message: "Lease created successfully", 
            lease: lease_agreement_json(@lease_agreement) 
          }, status: :created 
        }
      else
        @property = @rental_application.property
        format.html { render :new, status: :unprocessable_entity }
        format.json { 
          render json: { 
            errors: @lease_agreement.errors.full_messages 
          }, status: :unprocessable_entity 
        }
      end
    end
  end

  # GET /lease_agreements/:id/edit
  def edit
    unless can_edit_lease?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement), 
                  alert: "This lease cannot be edited."
      return
    end
    
    @property = @lease_agreement.property
  end

  # PATCH/PUT /lease_agreements/:id
  def update
    unless can_edit_lease?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement), 
                  alert: "This lease cannot be edited."
      return
    end
    
    respond_to do |format|
      if @lease_agreement.update(lease_agreement_params)
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          notice: "Lease agreement updated successfully!" 
        }
        format.json { 
          render json: { 
            message: "Lease updated successfully", 
            lease: lease_agreement_json(@lease_agreement) 
          } 
        }
      else
        @property = @lease_agreement.property
        format.html { render :edit, status: :unprocessable_entity }
        format.json { 
          render json: { 
            errors: @lease_agreement.errors.full_messages 
          }, status: :unprocessable_entity 
        }
      end
    end
  end

  # POST /lease_agreements/:id/sign_tenant
  def sign_tenant
    unless can_sign_as_tenant?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement), 
                  alert: "You cannot sign this lease."
      return
    end
    
    respond_to do |format|
      if @lease_agreement.sign_by_tenant!
        send_lease_signed_notification('tenant')
        
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          notice: "You have successfully signed the lease agreement!" 
        }
        format.json { 
          render json: { 
            message: "Lease signed by tenant", 
            lease: lease_agreement_json(@lease_agreement) 
          } 
        }
      else
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          alert: "Failed to sign lease agreement." 
        }
        format.json { 
          render json: { error: "Failed to sign lease" }, 
          status: :unprocessable_entity 
        }
      end
    end
  end

  # POST /lease_agreements/:id/sign_landlord
  def sign_landlord
    unless can_sign_as_landlord?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement), 
                  alert: "You cannot sign this lease."
      return
    end
    
    respond_to do |format|
      if @lease_agreement.sign_by_landlord!
        send_lease_signed_notification('landlord')
        
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          notice: "You have successfully signed the lease agreement!" 
        }
        format.json { 
          render json: { 
            message: "Lease signed by landlord", 
            lease: lease_agreement_json(@lease_agreement) 
          } 
        }
      else
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          alert: "Failed to sign lease agreement." 
        }
        format.json { 
          render json: { error: "Failed to sign lease" }, 
          status: :unprocessable_entity 
        }
      end
    end
  end

  # POST /lease_agreements/:id/activate
  def activate
    unless can_activate_lease?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement), 
                  alert: "This lease cannot be activated."
      return
    end
    
    respond_to do |format|
      if @lease_agreement.activate!
        send_lease_activated_notification
        
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          notice: "Lease agreement activated successfully!" 
        }
        format.json { 
          render json: { 
            message: "Lease activated", 
            lease: lease_agreement_json(@lease_agreement) 
          } 
        }
      else
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          alert: "Failed to activate lease agreement." 
        }
        format.json { 
          render json: { error: "Failed to activate lease" }, 
          status: :unprocessable_entity 
        }
      end
    end
  end

  # POST /lease_agreements/:id/terminate
  def terminate
    unless can_terminate_lease?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement), 
                  alert: "You cannot terminate this lease."
      return
    end
    
    termination_reason = params[:termination_reason]
    
    respond_to do |format|
      if @lease_agreement.terminate!(termination_reason)
        send_lease_terminated_notification(termination_reason)
        
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          notice: "Lease agreement terminated." 
        }
        format.json { 
          render json: { 
            message: "Lease terminated", 
            lease: lease_agreement_json(@lease_agreement) 
          } 
        }
      else
        format.html { 
          redirect_to lease_agreement_path(@lease_agreement), 
          alert: "Failed to terminate lease agreement." 
        }
        format.json { 
          render json: { error: "Failed to terminate lease" }, 
          status: :unprocessable_entity 
        }
      end
    end
  end

  private

  def set_lease_agreement
    @lease_agreement = LeaseAgreement.find(params[:id])
  end

  def authorize_access
    unless can_access_lease?(@lease_agreement)
      redirect_to lease_agreements_path, alert: "Access denied."
    end
  end

  def lease_agreement_params
    params.require(:lease_agreement).permit(
      :lease_start_date, :lease_end_date, :monthly_rent, :security_deposit_amount,
      :terms_and_conditions, additional_terms: {}
    )
  end

  def current_user_leases
    if current_user.landlord?
      # Landlord sees leases for their properties
      current_user.landlord_lease_agreements
    else
      # Tenant sees their own leases
      current_user.tenant_lease_agreements
    end
  end

  def can_access_lease?(lease)
    return true if lease.tenant == current_user
    return true if lease.landlord == current_user
    false
  end

  def can_manage_lease?(lease)
    lease.landlord == current_user
  end

  def can_sign_lease?(lease)
    return false if lease.status == 'signed'
    return true if lease.tenant == current_user && lease.tenant_signed_at.blank?
    return true if lease.landlord == current_user && lease.landlord_signed_at.blank?
    false
  end

  def can_create_lease_for_application?(application)
    return false unless application.status == 'approved'
    return false unless application.property.user == current_user
    true
  end

  def can_edit_lease?(lease)
    return false unless lease.landlord == current_user
    ['draft', 'pending_signatures'].include?(lease.status)
  end

  def can_sign_as_tenant?(lease)
    return false unless lease.tenant == current_user
    return false unless ['pending_signatures'].include?(lease.status)
    lease.tenant_signed_at.blank?
  end

  def can_sign_as_landlord?(lease)
    return false unless lease.landlord == current_user
    return false unless ['pending_signatures'].include?(lease.status)
    lease.landlord_signed_at.blank?
  end

  def can_activate_lease?(lease)
    return false unless lease.landlord == current_user
    return false unless lease.status == 'signed'
    lease.fully_signed?
  end

  def can_terminate_lease?(lease)
    return false unless lease.landlord == current_user
    ['active'].include?(lease.status)
  end

  def build_lease_from_application(application)
    LeaseAgreement.new(
      rental_application: application,
      property: application.property,
      landlord: application.property.user,
      tenant: application.tenant,
      lease_start_date: application.move_in_date,
      lease_end_date: application.move_in_date + 1.year,
      monthly_rent: application.property.price,
      status: 'draft'
    )
  end

  def calculate_lease_stats
    leases = current_user_leases
    
    {
      total: leases.count,
      draft: leases.where(status: 'draft').count,
      pending_signatures: leases.where(status: 'pending_signatures').count,
      signed: leases.where(status: 'signed').count,
      active: leases.where(status: 'active').count,
      terminated: leases.where(status: 'terminated').count
    }
  end

  def send_lease_created_notification
    # Send notification to tenant about new lease
    if @lease_agreement.tenant != current_user
      Notification.create_lease_created_notification(
        @lease_agreement.tenant,
        @lease_agreement
      )
    end
  end

  def send_lease_signed_notification(signer)
    # Send notification to the other party about signature
    recipient = signer == 'tenant' ? @lease_agreement.landlord : @lease_agreement.tenant

    if recipient != current_user
      Notification.create_lease_signed_notification(
        recipient,
        @lease_agreement,
        signer
      )
    end
  end

  def send_lease_activated_notification
    # Send notification to tenant about lease activation
    if @lease_agreement.tenant != current_user
      Notification.create_lease_activated_notification(
        @lease_agreement.tenant,
        @lease_agreement
      )
    end
  end

  def send_lease_terminated_notification(reason)
    # Send notification to tenant about lease termination
    if @lease_agreement.tenant != current_user
      Notification.create_lease_terminated_notification(
        @lease_agreement.tenant,
        @lease_agreement,
        reason
      )
    end
  end

  def lease_agreement_json(lease, include_details: false)
    json = {
      id: lease.id,
      status: lease.status,
      lease_start_date: lease.lease_start_date,
      lease_end_date: lease.lease_end_date,
      monthly_rent: lease.monthly_rent,
      security_deposit_amount: lease.security_deposit_amount,
      lease_number: lease.lease_number,
      created_at: lease.created_at,
      updated_at: lease.updated_at
    }
    
    if include_details
      json.merge!({
        terms_and_conditions: lease.terms_and_conditions,
        additional_terms: lease.additional_terms,
        tenant_signed_at: lease.tenant_signed_at,
        landlord_signed_at: lease.landlord_signed_at,
        fully_signed: lease.fully_signed?,
        property: {
          id: lease.property.id,
          title: lease.property.title,
          address: lease.property.address
        },
        tenant: {
          id: lease.tenant.id,
          name: lease.tenant.name,
          email: lease.tenant.email
        },
        landlord: {
          id: lease.landlord.id,
          name: lease.landlord.name,
          email: lease.landlord.email
        }
      })
    end
    
    json
  end
end
