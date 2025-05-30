class PaymentService
  include ActiveModel::Model

  attr_accessor :user, :amount, :payment_method_id, :description, :metadata

  def initialize(attributes = {})
    super
    @stripe_api_key = Rails.application.credentials.stripe&.secret_key
    raise "Stripe secret key not configured" unless @stripe_api_key

    Stripe.api_key = @stripe_api_key
  end

  # Create a payment intent for one-time payments
  def create_payment_intent(payment:, confirm: false)
    validate_payment!(payment)

    intent_params = {
      amount: (payment.amount * 100).to_i, # Convert to cents
      currency: "usd",
      payment_method: payment.payment_method&.stripe_payment_method_id,
      customer: get_or_create_stripe_customer(payment.user),
      description: payment.description,
      metadata: {
        payment_id: payment.id,
        lease_agreement_id: payment.lease_agreement_id,
        payment_type: payment.payment_type,
        user_id: payment.user_id
      }.merge(payment.metadata || {}),
      confirm: confirm,
      return_url: "#{Rails.application.config.base_url}/payments/#{payment.id}/confirm"
    }

    begin
      stripe_intent = Stripe::PaymentIntent.create(intent_params)

      payment.update!(
        stripe_payment_intent_id: stripe_intent.id,
        status: stripe_intent.status == "succeeded" ? "succeeded" : "processing"
      )

      if stripe_intent.status == "succeeded"
        payment.mark_as_succeeded!(
          stripe_charge_id: stripe_intent.charges.data.first&.id,
          paid_at: Time.current
        )
      end

      {
        success: true,
        payment_intent: stripe_intent,
        payment: payment
      }
    rescue Stripe::StripeError => e
      payment.mark_as_failed!(failure_reason: e.message)

      {
        success: false,
        error: e.message,
        payment: payment
      }
    end
  end

  # Confirm a payment intent (for 3D Secure, etc.)
  def confirm_payment_intent(payment_intent_id)
    begin
      stripe_intent = Stripe::PaymentIntent.confirm(payment_intent_id)
      payment = Payment.find_by(stripe_payment_intent_id: payment_intent_id)

      if payment && stripe_intent.status == "succeeded"
        payment.mark_as_succeeded!(
          stripe_charge_id: stripe_intent.charges.data.first&.id,
          paid_at: Time.current
        )
      elsif payment && stripe_intent.status == "payment_failed"
        payment.mark_as_failed!(failure_reason: stripe_intent.last_payment_error&.message)
      end

      {
        success: stripe_intent.status == "succeeded",
        payment_intent: stripe_intent,
        payment: payment
      }
    rescue Stripe::StripeError => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Process automatic payment for recurring schedules
  def process_automatic_payment(payment:)
    return { success: false, error: "Payment method required for automatic payments" } unless payment.payment_method

    result = create_payment_intent(payment: payment, confirm: true)

    if result[:success] && result[:payment_intent].status == "succeeded"
      # Advance the payment schedule
      if payment.payment_type == "rent"
        schedule = payment.lease_agreement.payment_schedules.rent.active.first
        schedule&.advance_to_next_payment!
      end
    end

    result
  end

  # Add a payment method to a user
  def add_payment_method(user:, stripe_payment_method_id:, set_as_default: false)
    begin
      # Retrieve the payment method from Stripe
      stripe_pm = Stripe::PaymentMethod.retrieve(stripe_payment_method_id)

      # Get or create Stripe customer
      customer_id = get_or_create_stripe_customer(user)

      # Attach payment method to customer
      stripe_pm.attach(customer: customer_id)

      # Create local payment method record
      payment_method = PaymentMethod.create_from_stripe!(
        user: user,
        stripe_payment_method: stripe_pm
      )

      payment_method.make_default! if set_as_default

      {
        success: true,
        payment_method: payment_method
      }
    rescue Stripe::StripeError => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Remove a payment method
  def remove_payment_method(payment_method:)
    begin
      payment_method.detach_from_stripe!

      {
        success: true
      }
    rescue => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Create a refund
  def create_refund(payment:, amount: nil, reason: nil)
    return { success: false, error: "Payment not succeeded" } unless payment.succeeded?
    return { success: false, error: "No Stripe charge ID" } unless payment.stripe_charge_id

    begin
      refund_params = {
        charge: payment.stripe_charge_id,
        reason: reason || "requested_by_customer",
        metadata: {
          payment_id: payment.id,
          refund_reason: reason
        }
      }

      refund_params[:amount] = (amount * 100).to_i if amount

      stripe_refund = Stripe::Refund.create(refund_params)

      # Update payment status
      if stripe_refund.amount == (payment.amount * 100).to_i
        payment.update!(status: "refunded")
      end

      {
        success: true,
        refund: stripe_refund,
        payment: payment
      }
    rescue Stripe::StripeError => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Get payment history for a user
  def get_payment_history(user:, limit: 50, starting_after: nil)
    begin
      customer_id = user.stripe_customer_id
      return { success: false, error: "No Stripe customer found" } unless customer_id

      params = {
        customer: customer_id,
        limit: limit
      }
      params[:starting_after] = starting_after if starting_after

      charges = Stripe::Charge.list(params)

      {
        success: true,
        charges: charges
      }
    rescue Stripe::StripeError => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Setup future payments (for subscriptions)
  def setup_future_payment(user:, payment_method_id:)
    begin
      customer_id = get_or_create_stripe_customer(user)

      setup_intent = Stripe::SetupIntent.create({
        customer: customer_id,
        payment_method: payment_method_id,
        confirm: true,
        usage: "off_session"
      })

      {
        success: setup_intent.status == "succeeded",
        setup_intent: setup_intent
      }
    rescue Stripe::StripeError => e
      {
        success: false,
        error: e.message
      }
    end
  end

  private

  def get_or_create_stripe_customer(user)
    return user.stripe_customer_id if user.stripe_customer_id.present?

    customer = Stripe::Customer.create({
      email: user.email,
      name: user.name,
      metadata: {
        user_id: user.id,
        role: user.role
      }
    })

    user.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def validate_payment!(payment)
    raise ArgumentError, "Payment is required" unless payment
    raise ArgumentError, "Payment amount must be positive" unless payment.amount > 0
    raise ArgumentError, "Payment user is required" unless payment.user
  end
end
