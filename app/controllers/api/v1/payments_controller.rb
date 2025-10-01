class Api::V1::PaymentsController < ApplicationController
  before_action :authenticate_request
  before_action :set_payment, only: [ :show, :retry, :cancel ]
  before_action :set_lease_agreement, only: [ :index, :create ]

  # GET /api/v1/payments
  # GET /api/v1/lease_agreements/:lease_agreement_id/payments
  def index
    @payments = if params[:lease_agreement_id]
      authorize_lease_access(@lease_agreement)
      @lease_agreement.payments
    else
      current_user.payments
    end

    # Apply filters
    @payments = @payments.where(status: params[:status]) if params[:status].present?
    @payments = @payments.where(payment_type: params[:payment_type]) if params[:payment_type].present?

    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @payments = @payments.where(due_date: params[:start_date]..params[:end_date])
    end

    # Pagination
    page = params[:page] || 1
    per_page = [ params[:per_page]&.to_i || 25, 100 ].min

    @payments = @payments.includes(:lease_agreement, :payment_method, :user)
                        .order(created_at: :desc)
                        .page(page)
                        .per(per_page)

    render json: {
      payments: @payments.map { |payment| payment_json(payment) },
      pagination: pagination_meta(@payments)
    }
  end

  # GET /api/v1/payments/:id
  def show
    authorize_payment_access(@payment)

    render json: {
      payment: payment_json(@payment, include_details: true)
    }
  end

  # POST /api/v1/lease_agreements/:lease_agreement_id/payments
  def create
    authorize_lease_access(@lease_agreement)

    @payment = @lease_agreement.payments.build(payment_params)
    @payment.user = current_user

    if @payment.save
      # Process payment if payment method is provided
      if params[:payment_method_id].present?
        payment_method = current_user.payment_methods.find(params[:payment_method_id])
        @payment.update!(payment_method: payment_method)

        payment_service = PaymentService.new
        result = payment_service.create_payment_intent(
          payment: @payment,
          confirm: params[:confirm_immediately] == true
        )

        if result[:success]
          render json: {
            payment: payment_json(@payment, include_details: true),
            client_secret: result[:client_secret]
          }, status: :created
        else
          render json: {
            error: result[:error],
            payment: payment_json(@payment, include_details: true)
          }, status: :unprocessable_entity
        end
      else
        render json: {
          payment: payment_json(@payment, include_details: true)
        }, status: :created
      end
    else
      render json: {
        errors: @payment.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/payments/:id/retry
  def retry
    authorize_payment_access(@payment)

    unless @payment.can_retry?
      render json: {
        error: "Payment cannot be retried in its current state"
      }, status: :unprocessable_entity
      return
    end

    payment_method_id = params[:payment_method_id]
    if payment_method_id.present?
      payment_method = current_user.payment_methods.find(payment_method_id)
      @payment.update!(payment_method: payment_method)
    end

    unless @payment.payment_method
      render json: {
        error: "Payment method is required to retry payment"
      }, status: :unprocessable_entity
      return
    end

    payment_service = PaymentService.new
    result = payment_service.create_payment_intent(
      payment: @payment,
      confirm: params[:confirm_immediately] == true
    )

    if result[:success]
      render json: {
        payment: payment_json(@payment, include_details: true),
        client_secret: result[:client_secret]
      }
    else
      render json: {
        error: result[:error],
        payment: payment_json(@payment, include_details: true)
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/payments/:id/cancel
  def cancel
    authorize_payment_access(@payment)

    unless @payment.pending? || @payment.processing?
      render json: {
        error: "Only pending or processing payments can be canceled"
      }, status: :unprocessable_entity
      return
    end

    payment_service = PaymentService.new
    result = payment_service.cancel_payment_intent(@payment)

    if result[:success]
      render json: {
        payment: payment_json(@payment, include_details: true),
        message: "Payment canceled successfully"
      }
    else
      render json: {
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/payments/summary
  def summary
    # Get payment summary for current user
    start_date = params[:start_date]&.to_date || 1.year.ago.to_date
    end_date = params[:end_date]&.to_date || Date.current

    payments = current_user.payments.where(due_date: start_date..end_date)

    summary = {
      total_payments: payments.count,
      total_amount: payments.sum(:amount),
      successful_payments: payments.succeeded.count,
      successful_amount: payments.succeeded.sum(:amount),
      failed_payments: payments.failed.count,
      failed_amount: payments.failed.sum(:amount),
      pending_payments: payments.pending.count,
      pending_amount: payments.pending.sum(:amount),
      overdue_payments: payments.overdue.count,
      overdue_amount: payments.overdue.sum(:amount),
      by_type: payments.group(:payment_type).sum(:amount),
      by_month: payments.group_by_month(:due_date, range: start_date..end_date).sum(:amount)
    }

    render json: { summary: summary }
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def set_lease_agreement
    @lease_agreement = LeaseAgreement.find(params[:lease_agreement_id]) if params[:lease_agreement_id]
  end

  def authorize_lease_access(lease)
    unless lease.tenant == current_user || lease.landlord == current_user
      render json: { error: "Access denied" }, status: :forbidden
    end
  end

  def authorize_payment_access(payment)
    lease = payment.lease_agreement
    unless payment.user == current_user || lease.landlord == current_user
      render json: { error: "Access denied" }, status: :forbidden
    end
  end

  def payment_params
    params.require(:payment).permit(
      :payment_type, :amount, :due_date, :description, :metadata
    )
  end

  def payment_json(payment, include_details: false)
    json = {
      id: payment.id,
      payment_number: payment.payment_number,
      payment_type: payment.payment_type,
      amount: payment.amount.to_f,
      status: payment.status,
      due_date: payment.due_date,
      description: payment.description,
      created_at: payment.created_at,
      updated_at: payment.updated_at
    }

    if include_details
      json.merge!({
        processed_at: payment.processed_at,
        failure_reason: payment.failure_reason,
        stripe_payment_intent_id: payment.stripe_payment_intent_id,
        metadata: payment.metadata,
        lease_agreement: {
          id: payment.lease_agreement.id,
          lease_number: payment.lease_agreement.lease_number,
          property: {
            id: payment.lease_agreement.property.id,
            address: payment.lease_agreement.property.address
          }
        },
        payment_method: payment.payment_method ? {
          id: payment.payment_method.id,
          display_name: payment.payment_method.display_name,
          payment_method_type: payment.payment_method.payment_method_type
        } : nil,
        user: {
          id: payment.user.id,
          name: payment.user.name,
          email: payment.user.email
        }
      })

      # Add calculated fields
      json[:overdue] = payment.overdue?
      json[:days_overdue] = payment.days_overdue if payment.overdue?
      json[:late_fee_amount] = payment.calculate_late_fee if payment.late_fee_applicable?
      json[:can_retry] = payment.can_retry?
    end

    json
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
