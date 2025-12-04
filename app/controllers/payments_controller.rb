class PaymentsController < ApplicationController
  before_action :authenticate_request
  before_action :set_payment, only: [ :show, :pay, :cancel, :refund ]
  before_action :authorize_access, only: [ :show, :pay, :cancel, :refund ]

  # GET /payments
  def index
    @payments = current_user_payments
               .includes(:lease_agreement, :payment_method, :user)
               .order(created_at: :desc)
               .page(params[:page])
               .per(20)

    # Filter by status if provided
    @payments = @payments.where(status: params[:status]) if params[:status].present?

    # Filter by payment type if provided
    @payments = @payments.where(payment_type: params[:type]) if params[:type].present?

    # Statistics for dashboard
    @stats = calculate_payment_stats
    @overdue_payments = current_user_payments.overdue.limit(5)
    @upcoming_payments = current_user_payments.due_soon.limit(5)
  end

  # GET /payments/:id
  def show
    @lease_agreement = @payment.lease_agreement
    @property = @lease_agreement.property
    # Ensure photos are loaded to avoid N+1 queries in views
    @property = Property.with_attached_photos.find(@property.id) unless @property.association(:photos_attachments).loaded?
    @can_pay = can_pay_payment?(@payment)
    @can_refund = can_refund_payment?(@payment)
  end

  # GET /lease_agreements/:lease_agreement_id/payments/new
  def new
    @lease_agreement = LeaseAgreement.find(params[:lease_agreement_id])

    unless can_create_payment_for_lease?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement),
                  alert: "You don't have permission to create payments for this lease."
      return
    end

    @payment = @lease_agreement.payments.build
    @payment.user = current_user
    @payment.payment_type = params[:payment_type] || "rent"
    @payment.amount = determine_default_amount(@lease_agreement, @payment.payment_type)
    @payment.due_date = determine_default_due_date(@payment.payment_type)

    @property = @lease_agreement.property
    @payment_methods = current_user.payment_methods.order(:created_at)
  end

  # POST /lease_agreements/:lease_agreement_id/payments
  def create
    @lease_agreement = LeaseAgreement.find(params[:lease_agreement_id])

    unless can_create_payment_for_lease?(@lease_agreement)
      redirect_to lease_agreement_path(@lease_agreement),
                  alert: "You don't have permission to create payments for this lease."
      return
    end

    @payment = @lease_agreement.payments.build(payment_params)
    @payment.user = current_user

    respond_to do |format|
      if @payment.save
        format.html {
          redirect_to payment_path(@payment),
          notice: "Payment created successfully!"
        }
        format.json {
          render json: {
            message: "Payment created successfully",
            payment: payment_json(@payment)
          }, status: :created
        }
      else
        @property = @lease_agreement.property
        @payment_methods = current_user.payment_methods.order(:created_at)
        format.html { render :new, status: :unprocessable_entity }
        format.json {
          render json: {
            errors: @payment.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # POST /payments/:id/pay
  def pay
    unless can_pay_payment?(@payment)
      redirect_to payment_path(@payment),
                  alert: "This payment cannot be processed."
      return
    end

    payment_method_id = params[:payment_method_id]
    payment_method = current_user.payment_methods.find_by(id: payment_method_id)

    unless payment_method
      redirect_to payment_path(@payment),
                  alert: "Please select a valid payment method."
      return
    end

    # Process payment using PaymentService
    service = PaymentService.new(
      user: current_user,
      amount: @payment.amount,
      payment_method_id: payment_method.stripe_payment_method_id,
      description: @payment.description,
      metadata: {
        payment_id: @payment.id,
        lease_agreement_id: @payment.lease_agreement_id,
        payment_type: @payment.payment_type
      }
    )

    result = service.create_payment_intent

    respond_to do |format|
      if result[:success]
        @payment.update!(
          payment_method: payment_method,
          stripe_payment_intent_id: result[:payment_intent].id,
          status: "processing"
        )

        format.html {
          redirect_to payment_path(@payment),
          notice: "Payment is being processed..."
        }
        format.json {
          render json: {
            success: true,
            client_secret: result[:payment_intent].client_secret,
            payment: payment_json(@payment)
          }
        }
      else
        format.html {
          redirect_to payment_path(@payment),
          alert: "Payment failed: #{result[:error]}"
        }
        format.json {
          render json: {
            success: false,
            error: result[:error]
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # POST /payments/:id/cancel
  def cancel
    unless can_cancel_payment?(@payment)
      redirect_to payment_path(@payment),
                  alert: "This payment cannot be canceled."
      return
    end

    respond_to do |format|
      if @payment.mark_as_canceled!
        format.html {
          redirect_to payment_path(@payment),
          notice: "Payment canceled successfully."
        }
        format.json {
          render json: {
            message: "Payment canceled",
            payment: payment_json(@payment)
          }
        }
      else
        format.html {
          redirect_to payment_path(@payment),
          alert: "Failed to cancel payment."
        }
        format.json {
          render json: { error: "Failed to cancel payment" },
          status: :unprocessable_entity
        }
      end
    end
  end

  # POST /payments/:id/refund
  def refund
    unless can_refund_payment?(@payment)
      redirect_to payment_path(@payment),
                  alert: "This payment cannot be refunded."
      return
    end

    refund_amount = params[:refund_amount]&.to_f || @payment.amount
    refund_reason = params[:refund_reason]

    # Process refund using PaymentService
    service = PaymentService.new
    result = service.refund_payment(@payment.stripe_charge_id, refund_amount, refund_reason)

    respond_to do |format|
      if result[:success]
        @payment.update!(
          status: "refunded",
          refund_amount: refund_amount,
          refund_reason: refund_reason,
          refunded_at: Time.current
        )

        format.html {
          redirect_to payment_path(@payment),
          notice: "Payment refunded successfully."
        }
        format.json {
          render json: {
            message: "Payment refunded",
            payment: payment_json(@payment)
          }
        }
      else
        format.html {
          redirect_to payment_path(@payment),
          alert: "Refund failed: #{result[:error]}"
        }
        format.json {
          render json: {
            success: false,
            error: result[:error]
          }, status: :unprocessable_entity
        }
      end
    end
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def authorize_access
    unless can_access_payment?(@payment)
      redirect_to payments_path, alert: "Access denied."
    end
  end

  def payment_params
    params.require(:payment).permit(
      :payment_type, :amount, :due_date, :description, :payment_method_id
    )
  end

  def current_user_payments
    if current_user.landlord?
      # Landlord sees payments for their properties
      Payment.joins(lease_agreement: :property)
             .where(properties: { user_id: current_user.id })
    else
      # Tenant sees their own payments
      current_user.payments
    end
  end

  def can_access_payment?(payment)
    return true if payment.user == current_user
    return true if payment.lease_agreement.property.user == current_user
    false
  end

  def can_pay_payment?(payment)
    return false unless payment.user == current_user
    [ "pending", "failed" ].include?(payment.status)
  end

  def can_cancel_payment?(payment)
    return false unless payment.user == current_user
    [ "pending", "processing" ].include?(payment.status)
  end

  def can_refund_payment?(payment)
    return false unless payment.lease_agreement.property.user == current_user
    payment.succeeded?
  end

  def can_create_payment_for_lease?(lease)
    return false unless lease.status == "active"
    return true if lease.tenant == current_user
    return true if lease.landlord == current_user
    false
  end

  def determine_default_amount(lease, payment_type)
    case payment_type
    when "rent"
      lease.monthly_rent
    when "security_deposit"
      lease.security_deposit_amount
    else
      0
    end
  end

  def determine_default_due_date(payment_type)
    case payment_type
    when "rent"
      Date.current.beginning_of_month.next_month
    else
      Date.current
    end
  end

  def calculate_payment_stats
    payments = current_user_payments

    {
      total: payments.count,
      pending: payments.pending.count,
      processing: payments.processing.count,
      succeeded: payments.succeeded.count,
      failed: payments.failed.count,
      total_amount: payments.succeeded.sum(:amount),
      overdue_count: payments.overdue.count,
      upcoming_count: payments.due_soon.count
    }
  end

  def payment_json(payment, include_details: false)
    json = {
      id: payment.id,
      status: payment.status,
      payment_type: payment.payment_type,
      amount: payment.amount,
      due_date: payment.due_date,
      payment_number: payment.payment_number,
      created_at: payment.created_at,
      updated_at: payment.updated_at
    }

    if include_details
      json.merge!({
        description: payment.description,
        paid_at: payment.paid_at,
        failure_reason: payment.failure_reason,
        refund_amount: payment.refund_amount,
        refund_reason: payment.refund_reason,
        lease_agreement: {
          id: payment.lease_agreement.id,
          property_title: payment.lease_agreement.property.title
        },
        payment_method: payment.payment_method ? {
          id: payment.payment_method.id,
          last_four: payment.payment_method.last_four,
          brand: payment.payment_method.brand
        } : nil
      })
    end

    json
  end
end
