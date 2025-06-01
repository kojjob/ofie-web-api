class PaymentMailer < ApplicationMailer
  default from: "noreply@ofie.com"

  def payment_success(payment)
    @payment = payment
    @tenant = payment.user
    @lease = payment.lease_agreement
    @property = @lease.property

    mail(
      to: @tenant.email,
      subject: "Payment Confirmation - #{@payment.payment_type.humanize} Payment Successful"
    )
  end

  def payment_failed(payment)
    @payment = payment
    @tenant = payment.user
    @lease = payment.lease_agreement
    @property = @lease.property

    mail(
      to: @tenant.email,
      subject: "Payment Failed - Action Required"
    )
  end

  def payment_due_reminder(payment)
    @payment = payment
    @tenant = payment.user
    @lease = payment.lease_agreement
    @property = @lease.property
    @days_until_due = (payment.due_date - Date.current).to_i

    subject_text = if @days_until_due <= 0
      "Payment Due Today"
    elsif @days_until_due == 1
      "Payment Due Tomorrow"
    else
      "Payment Due in #{@days_until_due} Days"
    end

    mail(
      to: @tenant.email,
      subject: "#{subject_text} - #{@payment.payment_type.humanize} Payment"
    )
  end

  def payment_overdue(payment)
    @payment = payment
    @tenant = payment.user
    @lease = payment.lease_agreement
    @property = @lease.property
    @days_overdue = payment.days_overdue
    @late_fee = payment.calculate_late_fee

    mail(
      to: @tenant.email,
      subject: "Overdue Payment Notice - Immediate Action Required"
    )
  end

  def payment_method_required(payment)
    @payment = payment
    @tenant = payment.user
    @lease = payment.lease_agreement
    @property = @lease.property

    mail(
      to: @tenant.email,
      subject: "Payment Method Required - Auto-Payment Failed"
    )
  end

  def security_deposit_collected(security_deposit)
    @security_deposit = security_deposit
    @lease = security_deposit.lease_agreement
    @tenant = @lease.tenant
    @landlord = @lease.landlord
    @property = @lease.property

    mail(
      to: @tenant.email,
      subject: "Security Deposit Confirmation - #{@property.address}"
    )
  end

  def security_deposit_refund_processed(security_deposit)
    @security_deposit = security_deposit
    @lease = security_deposit.lease_agreement
    @tenant = @lease.tenant
    @property = @lease.property
    @refund_breakdown = security_deposit.generate_refund_breakdown

    mail(
      to: @tenant.email,
      subject: "Security Deposit Refund Processed - #{@property.address}"
    )
  end

  def monthly_payment_summary(user, month, year)
    @user = user
    @month = month
    @year = year
    @month_name = Date::MONTHNAMES[month]

    # Get all payments for the month
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    @payments = Payment.joins(:lease_agreement)
      .where(user: user)
      .where(due_date: start_date..end_date)
      .includes(:lease_agreement, :payment_method)
      .order(:due_date)

    @total_paid = @payments.succeeded.sum(:amount)
    @total_pending = @payments.pending.sum(:amount)
    @total_failed = @payments.failed.sum(:amount)

    mail(
      to: @user.email,
      subject: "Monthly Payment Summary - #{@month_name} #{@year}"
    )
  end

  def landlord_payment_notification(payment)
    @payment = payment
    @lease = payment.lease_agreement
    @landlord = @lease.landlord
    @tenant = payment.user
    @property = @lease.property

    mail(
      to: @landlord.email,
      subject: "Payment Received - #{@tenant.name} (#{@property.address})"
    )
  end

  def landlord_overdue_notification(payment)
    @payment = payment
    @lease = payment.lease_agreement
    @landlord = @lease.landlord
    @tenant = payment.user
    @property = @lease.property
    @days_overdue = payment.days_overdue

    mail(
      to: @landlord.email,
      subject: "Overdue Payment Alert - #{@tenant.name} (#{@property.address})"
    )
  end
end
