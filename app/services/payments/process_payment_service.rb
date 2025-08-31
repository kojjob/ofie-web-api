module Payments
  class ProcessPaymentService < ApplicationService
    RETRY_LIMIT = 3

    def initialize(lease_agreement:, payment_method:, amount: nil)
      @lease_agreement = lease_agreement
      @payment_method = payment_method
      @amount = amount || lease_agreement.rent_amount
      @retry_count = 0
    end

    def call
      return failure("Invalid payment amount") unless valid_amount?
      return failure("Payment method not active") unless payment_method.active?

      with_transaction do
        payment = create_payment_record

        begin
          charge = process_stripe_payment(payment)

          if charge.status == "succeeded"
            handle_successful_payment(payment, charge)
          else
            handle_failed_payment(payment, charge)
          end
        rescue Stripe::CardError => e
          handle_card_error(payment, e)
        rescue Stripe::StripeError => e
          handle_stripe_error(payment, e)
        end
      end
    end

    private

    attr_reader :lease_agreement, :payment_method, :amount, :retry_count

    def valid_amount?
      amount.present? && amount > 0
    end

    def create_payment_record
      Payment.create!(
        user_id: lease_agreement.tenant_id,
        lease_agreement_id: lease_agreement.id,
        amount: amount,
        status: "pending",
        payment_method_id: payment_method.id,
        payment_type: determine_payment_type,
        due_date: calculate_due_date,
        metadata: {
          property_id: lease_agreement.property_id,
          landlord_id: lease_agreement.landlord_id
        }
      )
    end

    def process_stripe_payment(payment)
      Stripe::Charge.create(
        amount: (amount * 100).to_i, # Convert to cents
        currency: "usd",
        customer: payment_method.stripe_customer_id,
        source: payment_method.stripe_payment_method_id,
        description: payment_description(payment),
        metadata: {
          payment_id: payment.id,
          lease_agreement_id: lease_agreement.id,
          tenant_id: lease_agreement.tenant_id
        },
        capture: true
      )
    end

    def handle_successful_payment(payment, charge)
      payment.update!(
        status: "completed",
        stripe_charge_id: charge.id,
        processed_at: Time.current,
        transaction_details: {
          charge_id: charge.id,
          receipt_url: charge.receipt_url,
          billing_details: charge.billing_details.to_h
        }
      )

      send_payment_confirmations(payment)
      update_lease_payment_status
      create_payment_receipt(payment)

      log_execution("Payment processed successfully: #{payment.id}")
      success(payment: payment, charge: charge)
    end

    def handle_failed_payment(payment, charge)
      payment.update!(
        status: "failed",
        stripe_charge_id: charge.id,
        error_message: charge.failure_message || "Payment failed",
        failed_at: Time.current
      )

      send_failure_notifications(payment)
      schedule_retry_if_applicable(payment)

      failure("Payment failed: #{charge.failure_message}")
    end

    def handle_card_error(payment, error)
      payment.update!(
        status: "failed",
        error_message: error.message,
        error_code: error.code,
        failed_at: Time.current
      )

      send_card_error_notification(payment, error)

      log_execution("Card error: #{error.message}", :error)
      failure("Card error: #{error.message}")
    end

    def handle_stripe_error(payment, error)
      payment.update!(
        status: "error",
        error_message: error.message,
        failed_at: Time.current
      )

      # Retry for network errors
      if should_retry?(error) && retry_count < RETRY_LIMIT
        @retry_count += 1
        log_execution("Retrying payment (attempt #{retry_count})", :warn)
        return call
      end

      log_execution("Stripe error: #{error.message}", :error)
      failure("Payment processing error. Please try again later.")
    end

    def send_payment_confirmations(payment)
      # Send email to tenant
      PaymentMailer.payment_confirmation(payment).deliver_later

      # Send email to landlord
      PaymentMailer.payment_received(payment).deliver_later

      # Create notifications
      create_notification(
        lease_agreement.tenant,
        "Payment Successful",
        "Your payment of $#{amount} has been processed successfully."
      )

      create_notification(
        lease_agreement.landlord,
        "Payment Received",
        "Payment of $#{amount} received from #{lease_agreement.tenant.name}."
      )
    end

    def send_failure_notifications(payment)
      PaymentMailer.payment_failed(payment).deliver_later

      create_notification(
        lease_agreement.tenant,
        "Payment Failed",
        "Your payment of $#{amount} could not be processed.",
        "high"
      )
    end

    def send_card_error_notification(payment, error)
      PaymentMailer.card_error(payment, error).deliver_later

      create_notification(
        lease_agreement.tenant,
        "Card Issue",
        "There was an issue with your payment method: #{error.message}",
        "high"
      )
    end

    def create_notification(user, title, message, priority = "medium")
      Notification.create!(
        user: user,
        title: title,
        message: message,
        notification_type: "payment",
        priority: priority
      )
    rescue StandardError => e
      log_execution("Notification creation failed: #{e.message}", :warn)
    end

    def update_lease_payment_status
      # Update last payment date
      lease_agreement.update!(last_payment_date: Time.current)

      # Check if all payments are up to date
      if lease_agreement.payments.where(status: "pending").none?
        lease_agreement.update!(payment_status: "current")
      end
    end

    def create_payment_receipt(payment)
      # Generate PDF receipt
      ReceiptGeneratorJob.perform_later(payment.id)
    end

    def schedule_retry_if_applicable(payment)
      return unless payment.payment_type == "recurring"

      # Schedule retry in 3 days
      RetryPaymentJob.set(wait: 3.days).perform_later(payment.id)
    end

    def determine_payment_type
      params[:payment_type] || "one_time"
    end

    def calculate_due_date
      params[:due_date] || Time.current
    end

    def payment_description(payment)
      "Rent payment for #{lease_agreement.property.address} - #{payment.created_at.strftime('%B %Y')}"
    end

    def should_retry?(error)
      error.is_a?(Stripe::APIConnectionError) ||
      error.is_a?(Stripe::RateLimitError)
    end
  end
end
