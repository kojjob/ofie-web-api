class StripeWebhookJob < ApplicationJob
  queue_as :default

  def perform(event_data)
    event_type = event_data["type"]
    event_object = event_data["data"]["object"]

    Rails.logger.info "Processing Stripe webhook: #{event_type}"

    case event_type
    when "payment_intent.succeeded"
      handle_payment_succeeded(event_object)
    when "payment_intent.payment_failed"
      handle_payment_failed(event_object)
    when "payment_intent.processing"
      handle_payment_processing(event_object)
    when "payment_intent.canceled"
      handle_payment_canceled(event_object)
    when "payment_method.attached"
      handle_payment_method_attached(event_object)
    when "payment_method.detached"
      handle_payment_method_detached(event_object)
    when "customer.created"
      handle_customer_created(event_object)
    when "customer.updated"
      handle_customer_updated(event_object)
    when "invoice.payment_succeeded"
      handle_invoice_payment_succeeded(event_object)
    when "invoice.payment_failed"
      handle_invoice_payment_failed(event_object)
    else
      Rails.logger.info "Unhandled Stripe webhook event: #{event_type}"
    end
  rescue => e
    Rails.logger.error "Failed to process Stripe webhook #{event_type}: #{e.message}"
    raise e
  end

  private

  def handle_payment_succeeded(payment_intent)
    payment = find_payment_by_stripe_id(payment_intent["id"])
    return unless payment

    payment.update!(
      status: "succeeded",
      stripe_payment_intent_id: payment_intent["id"],
      processed_at: Time.current,
      metadata: payment.metadata.merge({
        stripe_charges: payment_intent["charges"]["data"],
        payment_method_details: payment_intent["charges"]["data"].first&.dig("payment_method_details")
      })
    )

    # Send success notification
    PaymentNotificationJob.perform_later(payment, "payment_succeeded")

    Rails.logger.info "Payment #{payment.id} marked as succeeded"
  end

  def handle_payment_failed(payment_intent)
    payment = find_payment_by_stripe_id(payment_intent["id"])
    return unless payment

    last_payment_error = payment_intent["last_payment_error"]
    failure_reason = last_payment_error&.dig("message") || "Payment failed"

    payment.update!(
      status: "failed",
      stripe_payment_intent_id: payment_intent["id"],
      failure_reason: failure_reason,
      metadata: payment.metadata.merge({
        stripe_error: last_payment_error,
        failure_code: last_payment_error&.dig("code")
      })
    )

    # Send failure notification
    PaymentNotificationJob.perform_later(payment, "payment_failed")

    Rails.logger.info "Payment #{payment.id} marked as failed: #{failure_reason}"
  end

  def handle_payment_processing(payment_intent)
    payment = find_payment_by_stripe_id(payment_intent["id"])
    return unless payment

    payment.update!(
      status: "processing",
      stripe_payment_intent_id: payment_intent["id"]
    )

    Rails.logger.info "Payment #{payment.id} is processing"
  end

  def handle_payment_canceled(payment_intent)
    payment = find_payment_by_stripe_id(payment_intent["id"])
    return unless payment

    cancellation_reason = payment_intent["cancellation_reason"] || "Payment canceled"

    payment.update!(
      status: "canceled",
      stripe_payment_intent_id: payment_intent["id"],
      failure_reason: cancellation_reason,
      metadata: payment.metadata.merge({
        cancellation_reason: cancellation_reason
      })
    )

    Rails.logger.info "Payment #{payment.id} was canceled: #{cancellation_reason}"
  end

  def handle_payment_method_attached(payment_method)
    stripe_customer_id = payment_method["customer"]
    user = User.find_by(stripe_customer_id: stripe_customer_id)
    return unless user

    # Create or update payment method record
    existing_method = PaymentMethod.find_by(
      user: user,
      stripe_payment_method_id: payment_method["id"]
    )

    if existing_method
      update_payment_method_from_stripe(existing_method, payment_method)
    else
      PaymentMethod.create_from_stripe!(user, payment_method)
    end

    Rails.logger.info "Payment method #{payment_method['id']} attached to user #{user.id}"
  end

  def handle_payment_method_detached(payment_method)
    existing_method = PaymentMethod.find_by(
      stripe_payment_method_id: payment_method["id"]
    )

    if existing_method
      existing_method.destroy!
      Rails.logger.info "Payment method #{payment_method['id']} detached and removed"
    end
  end

  def handle_customer_created(customer)
    # This might be handled elsewhere, but we can log it
    Rails.logger.info "Stripe customer created: #{customer['id']}"
  end

  def handle_customer_updated(customer)
    user = User.find_by(stripe_customer_id: customer["id"])
    return unless user

    # Update user information if needed
    if customer["email"] != user.email
      Rails.logger.info "Customer email mismatch for user #{user.id}: #{customer['email']} vs #{user.email}"
    end
  end

  def handle_invoice_payment_succeeded(invoice)
    # Handle subscription-based payments if implemented
    Rails.logger.info "Invoice payment succeeded: #{invoice['id']}"
  end

  def handle_invoice_payment_failed(invoice)
    # Handle subscription-based payment failures if implemented
    Rails.logger.info "Invoice payment failed: #{invoice['id']}"
  end

  def find_payment_by_stripe_id(stripe_payment_intent_id)
    payment = Payment.find_by(stripe_payment_intent_id: stripe_payment_intent_id)

    unless payment
      Rails.logger.warn "No payment found for Stripe payment intent: #{stripe_payment_intent_id}"
    end

    payment
  end

  def update_payment_method_from_stripe(payment_method_record, stripe_data)
    case stripe_data["type"]
    when "card"
      card = stripe_data["card"]
      payment_method_record.update!(
        last_four: card["last4"],
        brand: card["brand"],
        exp_month: card["exp_month"],
        exp_year: card["exp_year"],
        metadata: payment_method_record.metadata.merge({
          funding: card["funding"],
          country: card["country"]
        })
      )
    when "us_bank_account"
      bank_account = stripe_data["us_bank_account"]
      payment_method_record.update!(
        last_four: bank_account["last4"],
        bank_name: bank_account["bank_name"],
        account_type: bank_account["account_type"],
        metadata: payment_method_record.metadata.merge({
          routing_number: bank_account["routing_number"],
          account_holder_type: bank_account["account_holder_type"]
        })
      )
    end
  end
end
