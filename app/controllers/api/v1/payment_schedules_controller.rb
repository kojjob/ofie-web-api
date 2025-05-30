class Api::V1::PaymentSchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_schedule, only: [ :show, :update, :destroy, :activate, :deactivate, :toggle_auto_pay ]
  before_action :set_lease_agreement, only: [ :index, :create ]

  # GET /api/v1/payment_schedules
  # GET /api/v1/lease_agreements/:lease_agreement_id/payment_schedules
  def index
    @payment_schedules = if params[:lease_agreement_id]
      authorize_lease_access(@lease_agreement)
      @lease_agreement.payment_schedules
    else
      # Get schedules for all user's leases
      lease_ids = current_user.tenant_lease_agreements.pluck(:id) +
                  current_user.landlord_lease_agreements.pluck(:id)
      PaymentSchedule.where(lease_agreement_id: lease_ids.uniq)
    end

    # Apply filters
    @payment_schedules = @payment_schedules.where(is_active: params[:active]) if params[:active].present?
    @payment_schedules = @payment_schedules.where(auto_pay: params[:auto_pay]) if params[:auto_pay].present?
    @payment_schedules = @payment_schedules.where(payment_type: params[:payment_type]) if params[:payment_type].present?

    @payment_schedules = @payment_schedules.includes(:lease_agreement)
                                           .order(:next_payment_date)

    render json: {
      payment_schedules: @payment_schedules.map { |schedule| payment_schedule_json(schedule) }
    }
  end

  # GET /api/v1/payment_schedules/:id
  def show
    authorize_schedule_access(@payment_schedule)

    render json: {
      payment_schedule: payment_schedule_json(@payment_schedule, include_details: true)
    }
  end

  # POST /api/v1/lease_agreements/:lease_agreement_id/payment_schedules
  def create
    authorize_lease_access(@lease_agreement)

    # Only landlord can create payment schedules
    unless @lease_agreement.landlord == current_user
      render json: { error: "Only landlord can create payment schedules" }, status: :forbidden
      return
    end

    @payment_schedule = @lease_agreement.payment_schedules.build(payment_schedule_params)

    if @payment_schedule.save
      render json: {
        payment_schedule: payment_schedule_json(@payment_schedule, include_details: true)
      }, status: :created
    else
      render json: {
        errors: @payment_schedule.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/payment_schedules/:id
  def update
    authorize_schedule_access(@payment_schedule)

    # Only landlord can update payment schedules
    unless @payment_schedule.lease_agreement.landlord == current_user
      render json: { error: "Only landlord can update payment schedules" }, status: :forbidden
      return
    end

    if @payment_schedule.update(payment_schedule_update_params)
      render json: {
        payment_schedule: payment_schedule_json(@payment_schedule, include_details: true)
      }
    else
      render json: {
        errors: @payment_schedule.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/payment_schedules/:id
  def destroy
    authorize_schedule_access(@payment_schedule)

    # Only landlord can delete payment schedules
    unless @payment_schedule.lease_agreement.landlord == current_user
      render json: { error: "Only landlord can delete payment schedules" }, status: :forbidden
      return
    end

    @payment_schedule.destroy!

    render json: {
      message: "Payment schedule deleted successfully"
    }
  end

  # POST /api/v1/payment_schedules/:id/activate
  def activate
    authorize_schedule_access(@payment_schedule)

    # Only landlord can activate/deactivate schedules
    unless @payment_schedule.lease_agreement.landlord == current_user
      render json: { error: "Only landlord can activate payment schedules" }, status: :forbidden
      return
    end

    @payment_schedule.activate!

    render json: {
      payment_schedule: payment_schedule_json(@payment_schedule, include_details: true),
      message: "Payment schedule activated successfully"
    }
  end

  # POST /api/v1/payment_schedules/:id/deactivate
  def deactivate
    authorize_schedule_access(@payment_schedule)

    # Only landlord can activate/deactivate schedules
    unless @payment_schedule.lease_agreement.landlord == current_user
      render json: { error: "Only landlord can deactivate payment schedules" }, status: :forbidden
      return
    end

    @payment_schedule.deactivate!

    render json: {
      payment_schedule: payment_schedule_json(@payment_schedule, include_details: true),
      message: "Payment schedule deactivated successfully"
    }
  end

  # POST /api/v1/payment_schedules/:id/toggle_auto_pay
  def toggle_auto_pay
    authorize_schedule_access(@payment_schedule)

    # Both tenant and landlord can toggle auto-pay
    lease = @payment_schedule.lease_agreement
    unless lease.tenant == current_user || lease.landlord == current_user
      render json: { error: "Access denied" }, status: :forbidden
      return
    end

    if @payment_schedule.auto_pay?
      @payment_schedule.disable_auto_pay!
      message = "Auto-pay disabled successfully"
    else
      # Check if tenant has a default payment method
      if lease.tenant.payment_methods.default_methods.empty?
        render json: {
          error: "Cannot enable auto-pay: No default payment method found. Please add a payment method first."
        }, status: :unprocessable_entity
        return
      end

      @payment_schedule.enable_auto_pay!
      message = "Auto-pay enabled successfully"
    end

    render json: {
      payment_schedule: payment_schedule_json(@payment_schedule, include_details: true),
      message: message
    }
  end

  # GET /api/v1/payment_schedules/upcoming
  def upcoming
    # Get upcoming payments for current user
    lease_ids = current_user.tenant_lease_agreements.active.pluck(:id)

    upcoming_schedules = PaymentSchedule.active
                                        .where(lease_agreement_id: lease_ids)
                                        .where("next_payment_date <= ?", 30.days.from_now)
                                        .includes(:lease_agreement)
                                        .order(:next_payment_date)

    render json: {
      upcoming_schedules: upcoming_schedules.map { |schedule|
        payment_schedule_json(schedule).merge({
          days_until_due: schedule.days_until_due,
          due_today: schedule.due_today?,
          overdue: schedule.overdue?
        })
      }
    }
  end

  # POST /api/v1/payment_schedules/:id/create_payment
  def create_payment
    authorize_schedule_access(@payment_schedule)

    # Only tenant can manually create payments from schedules
    unless @payment_schedule.lease_agreement.tenant == current_user
      render json: { error: "Only tenant can create payments from schedules" }, status: :forbidden
      return
    end

    unless @payment_schedule.active?
      render json: { error: "Cannot create payment from inactive schedule" }, status: :unprocessable_entity
      return
    end

    begin
      payment = @payment_schedule.create_payment_for_current_period!

      render json: {
        payment: {
          id: payment.id,
          payment_number: payment.payment_number,
          amount: payment.amount.to_f,
          due_date: payment.due_date,
          status: payment.status
        },
        message: "Payment created successfully"
      }, status: :created
    rescue => e
      render json: {
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_payment_schedule
    @payment_schedule = PaymentSchedule.find(params[:id])
  end

  def set_lease_agreement
    @lease_agreement = LeaseAgreement.find(params[:lease_agreement_id]) if params[:lease_agreement_id]
  end

  def authorize_lease_access(lease)
    unless lease.tenant == current_user || lease.landlord == current_user
      render json: { error: "Access denied" }, status: :forbidden
    end
  end

  def authorize_schedule_access(schedule)
    lease = schedule.lease_agreement
    unless lease.tenant == current_user || lease.landlord == current_user
      render json: { error: "Access denied" }, status: :forbidden
    end
  end

  def payment_schedule_params
    params.require(:payment_schedule).permit(
      :payment_type, :amount, :frequency, :start_date, :end_date,
      :day_of_month, :auto_pay, :description, :metadata
    )
  end

  def payment_schedule_update_params
    params.require(:payment_schedule).permit(
      :amount, :frequency, :end_date, :day_of_month, :description, :metadata
    )
  end

  def payment_schedule_json(schedule, include_details: false)
    json = {
      id: schedule.id,
      payment_type: schedule.payment_type,
      amount: schedule.amount.to_f,
      frequency: schedule.frequency,
      next_payment_date: schedule.next_payment_date,
      is_active: schedule.is_active,
      auto_pay: schedule.auto_pay,
      created_at: schedule.created_at,
      updated_at: schedule.updated_at
    }

    if include_details
      json.merge!({
        start_date: schedule.start_date,
        end_date: schedule.end_date,
        day_of_month: schedule.day_of_month,
        description: schedule.description,
        metadata: schedule.metadata,
        lease_agreement: {
          id: schedule.lease_agreement.id,
          lease_number: schedule.lease_agreement.lease_number,
          property: {
            id: schedule.lease_agreement.property.id,
            address: schedule.lease_agreement.property.address
          },
          tenant: {
            id: schedule.lease_agreement.tenant.id,
            name: schedule.lease_agreement.tenant.name
          },
          landlord: {
            id: schedule.lease_agreement.landlord.id,
            name: schedule.lease_agreement.landlord.name
          }
        }
      })

      # Add calculated fields
      json[:due_today] = schedule.due_today?
      json[:overdue] = schedule.overdue?
      json[:days_until_due] = schedule.days_until_due
    end

    json
  end
end
