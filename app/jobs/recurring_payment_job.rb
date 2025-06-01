class RecurringPaymentJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting recurring payment processing at #{Time.current}"

    processed_count = 0
    failed_count = 0

    # Process all due payment schedules
    PaymentSchedule.active.auto_pay_enabled.find_each do |schedule|
      next unless schedule.due_today? || schedule.overdue?

      begin
        process_schedule_payment(schedule)
        processed_count += 1
      rescue => e
        Rails.logger.error "Failed to process payment for schedule #{schedule.id}: #{e.message}"
        failed_count += 1
      end
    end

    # Send payment reminders for upcoming due dates
    send_payment_reminders

    # Send overdue notifications
    send_overdue_notifications

    Rails.logger.info "Recurring payment processing completed. Processed: #{processed_count}, Failed: #{failed_count}"
  end

  private

  def process_schedule_payment(schedule)
    # Check if payment already exists for this period
    existing_payment = Payment.find_by(
      lease_agreement: schedule.lease_agreement,
      payment_type: schedule.payment_type,
      due_date: schedule.next_payment_date
    )

    if existing_payment
      Rails.logger.info "Payment already exists for schedule #{schedule.id}, skipping"
      return
    end

    # Get tenant's default payment method
    tenant = schedule.lease_agreement.tenant
    payment_method = tenant.payment_methods.default_methods.first

    unless payment_method
      Rails.logger.warn "No default payment method for user #{tenant.id}, skipping auto-payment"
      # Send notification about missing payment method
      PaymentNotificationJob.perform_later(
        create_pending_payment(schedule),
        "payment_method_required"
      )
      return
    end

    # Create payment record
    payment = Payment.create!(
      lease_agreement: schedule.lease_agreement,
      user: tenant,
      payment_method: payment_method,
      payment_type: schedule.payment_type,
      amount: schedule.amount,
      due_date: schedule.next_payment_date,
      description: schedule.description || generate_payment_description(schedule)
    )

    # Process payment through Stripe
    payment_service = PaymentService.new
    result = payment_service.process_automatic_payment(payment: payment)

    if result[:success]
      Rails.logger.info "Successfully processed automatic payment #{payment.id}"
      # Advance the schedule to next payment date
      schedule.advance_to_next_payment!
    else
      Rails.logger.error "Failed to process automatic payment #{payment.id}: #{result[:error]}"
      # The payment status will be updated by the service
    end
  end

  def create_pending_payment(schedule)
    Payment.create!(
      lease_agreement: schedule.lease_agreement,
      user: schedule.lease_agreement.tenant,
      payment_type: schedule.payment_type,
      amount: schedule.amount,
      due_date: schedule.next_payment_date,
      description: schedule.description || generate_payment_description(schedule),
      status: "pending"
    )
  end

  def send_payment_reminders
    # Send reminders 7 days before due date
    upcoming_payments = Payment.pending
      .joins(:lease_agreement)
      .where("due_date = ? AND lease_agreements.status = ?", 7.days.from_now.to_date, "active")

    upcoming_payments.find_each do |payment|
      PaymentNotificationJob.perform_later(payment, "payment_due_reminder")
    end

    # Send reminders 3 days before due date
    urgent_payments = Payment.pending
      .joins(:lease_agreement)
      .where("due_date = ? AND lease_agreements.status = ?", 3.days.from_now.to_date, "active")

    urgent_payments.find_each do |payment|
      PaymentNotificationJob.perform_later(payment, "payment_due_reminder")
    end
  end

  def send_overdue_notifications
    overdue_payments = Payment.overdue
      .joins(:lease_agreement)
      .where("lease_agreements.status = ?", "active")

    overdue_payments.find_each do |payment|
      # Send overdue notification
      PaymentNotificationJob.perform_later(payment, "payment_overdue")

      # Create late fee if applicable
      if payment.late_fee_applicable?
        create_late_fee_payment(payment)
      end
    end
  end

  def create_late_fee_payment(original_payment)
    # Check if late fee already exists
    existing_late_fee = Payment.find_by(
      lease_agreement: original_payment.lease_agreement,
      payment_type: "late_fee",
      metadata: { original_payment_id: original_payment.id }
    )

    return if existing_late_fee

    late_fee_amount = original_payment.calculate_late_fee
    return if late_fee_amount <= 0

    Payment.create!(
      lease_agreement: original_payment.lease_agreement,
      user: original_payment.user,
      payment_type: "late_fee",
      amount: late_fee_amount,
      due_date: Date.current,
      description: "Late fee for overdue #{original_payment.payment_type} payment",
      metadata: {
        original_payment_id: original_payment.id,
        days_overdue: original_payment.days_overdue
      }
    )

    Rails.logger.info "Created late fee payment of $#{late_fee_amount} for payment #{original_payment.id}"
  end

  def generate_payment_description(schedule)
    case schedule.payment_type
    when "rent"
      "Monthly rent for #{schedule.next_payment_date.strftime('%B %Y')}"
    when "utility"
      "Utility payment for #{schedule.next_payment_date.strftime('%B %Y')}"
    else
      "#{schedule.payment_type.humanize} payment for #{schedule.next_payment_date.strftime('%B %Y')}"
    end
  end
end
