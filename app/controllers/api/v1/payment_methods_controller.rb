class Api::V1::PaymentMethodsController < ApplicationController
  before_action :authenticate_request
  before_action :set_payment_method, only: [ :show, :update, :destroy, :make_default ]

  # GET /api/v1/payment_methods
  def index
    @payment_methods = current_user.payment_methods
                                  .includes(:user)
                                  .order(is_default: :desc, created_at: :desc)

    render json: {
      payment_methods: @payment_methods.map { |pm| payment_method_json(pm) }
    }
  end

  # GET /api/v1/payment_methods/:id
  def show
    render json: {
      payment_method: payment_method_json(@payment_method, include_details: true)
    }
  end

  # POST /api/v1/payment_methods
  def create
    payment_service = PaymentService.new

    case params[:type]
    when "stripe_setup_intent"
      # Create setup intent for adding payment method
      result = payment_service.create_setup_intent(current_user)

      if result[:success]
        render json: {
          setup_intent: {
            client_secret: result[:client_secret],
            id: result[:setup_intent_id]
          }
        }, status: :created
      else
        render json: {
          error: result[:error]
        }, status: :unprocessable_entity
      end

    when "stripe_payment_method"
      # Attach existing Stripe payment method
      stripe_payment_method_id = params[:stripe_payment_method_id]

      unless stripe_payment_method_id.present?
        render json: {
          error: "stripe_payment_method_id is required"
        }, status: :unprocessable_entity
        return
      end

      result = payment_service.attach_payment_method(
        user: current_user,
        stripe_payment_method_id: stripe_payment_method_id
      )

      if result[:success]
        payment_method = PaymentMethod.create_from_stripe!(
          current_user,
          result[:payment_method]
        )

        render json: {
          payment_method: payment_method_json(payment_method, include_details: true)
        }, status: :created
      else
        render json: {
          error: result[:error]
        }, status: :unprocessable_entity
      end

    else
      render json: {
        error: 'Invalid payment method type. Use "stripe_setup_intent" or "stripe_payment_method"'
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/payment_methods/:id
  def update
    if @payment_method.update(payment_method_update_params)
      render json: {
        payment_method: payment_method_json(@payment_method, include_details: true)
      }
    else
      render json: {
        errors: @payment_method.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/payment_methods/:id
  def destroy
    if @payment_method.is_default && current_user.payment_methods.count > 1
      render json: {
        error: "Cannot delete default payment method. Please set another payment method as default first."
      }, status: :unprocessable_entity
      return
    end

    payment_service = PaymentService.new
    result = payment_service.detach_payment_method(@payment_method)

    if result[:success]
      @payment_method.destroy!
      render json: {
        message: "Payment method deleted successfully"
      }
    else
      render json: {
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/payment_methods/:id/make_default
  def make_default
    @payment_method.make_default!

    render json: {
      payment_method: payment_method_json(@payment_method, include_details: true),
      message: "Payment method set as default successfully"
    }
  end

  # POST /api/v1/payment_methods/setup_intent_success
  def setup_intent_success
    setup_intent_id = params[:setup_intent_id]

    unless setup_intent_id.present?
      render json: {
        error: "setup_intent_id is required"
      }, status: :unprocessable_entity
      return
    end

    payment_service = PaymentService.new
    result = payment_service.retrieve_setup_intent(setup_intent_id)

    if result[:success] && result[:setup_intent]["status"] == "succeeded"
      payment_method_id = result[:setup_intent]["payment_method"]

      # Retrieve the payment method details
      pm_result = payment_service.retrieve_payment_method(payment_method_id)

      if pm_result[:success]
        payment_method = PaymentMethod.create_from_stripe!(
          current_user,
          pm_result[:payment_method]
        )

        render json: {
          payment_method: payment_method_json(payment_method, include_details: true),
          message: "Payment method added successfully"
        }, status: :created
      else
        render json: {
          error: pm_result[:error]
        }, status: :unprocessable_entity
      end
    else
      render json: {
        error: result[:error] || "Setup intent was not successful"
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/payment_methods/validate
  def validate
    payment_method_id = params[:payment_method_id]

    unless payment_method_id.present?
      render json: {
        error: "payment_method_id is required"
      }, status: :unprocessable_entity
      return
    end

    payment_method = current_user.payment_methods.find_by(id: payment_method_id)

    unless payment_method
      render json: {
        error: "Payment method not found"
      }, status: :not_found
      return
    end

    validation_result = {
      valid: true,
      issues: []
    }

    # Check if payment method is expired
    if payment_method.expired?
      validation_result[:valid] = false
      validation_result[:issues] << "Payment method has expired"
    elsif payment_method.expires_soon?
      validation_result[:issues] << "Payment method expires soon"
    end

    # Additional validations can be added here

    render json: {
      validation: validation_result,
      payment_method: payment_method_json(payment_method)
    }
  end

  private

  def set_payment_method
    @payment_method = current_user.payment_methods.find(params[:id])
  end

  def payment_method_update_params
    params.require(:payment_method).permit(:nickname)
  end

  def payment_method_json(payment_method, include_details: false)
    json = {
      id: payment_method.id,
      payment_method_type: payment_method.payment_method_type,
      display_name: payment_method.display_name,
      is_default: payment_method.is_default,
      created_at: payment_method.created_at,
      updated_at: payment_method.updated_at
    }

    # Add type-specific information
    if payment_method.card?
      json.merge!({
        last_four: payment_method.last_four,
        brand: payment_method.brand,
        exp_month: payment_method.exp_month,
        exp_year: payment_method.exp_year
      })
    elsif payment_method.bank_account?
      json.merge!({
        last_four: payment_method.last_four,
        bank_name: payment_method.bank_name,
        account_type: payment_method.account_type
      })
    end

    if include_details
      json.merge!({
        nickname: payment_method.nickname,
        stripe_payment_method_id: payment_method.stripe_payment_method_id,
        metadata: payment_method.metadata,
        expired: payment_method.expired?,
        expires_soon: payment_method.expires_soon?
      })
    end

    json
  end
end
