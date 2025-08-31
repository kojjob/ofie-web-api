class PaymentsQuery < ApplicationQuery
  def initialize(relation = Payment.all)
    super(relation)
  end

  # Filter by user (tenant or landlord)
  def for_user(user)
    return self unless user.present?
    
    @relation = @relation
      .joins(:lease_agreement)
      .where(
        "payments.user_id = :user_id OR lease_agreements.landlord_id = :user_id",
        user_id: user.id
      )
    self
  end

  # Filter by tenant
  def by_tenant(tenant_id)
    return self unless tenant_id.present?
    
    @relation = @relation.where(user_id: tenant_id)
    self
  end

  # Filter by landlord
  def by_landlord(landlord_id)
    return self unless landlord_id.present?
    
    @relation = @relation
      .joins(:lease_agreement)
      .where(lease_agreements: { landlord_id: landlord_id })
    self
  end

  # Filter by lease agreement
  def for_lease(lease_agreement_id)
    return self unless lease_agreement_id.present?
    
    @relation = @relation.where(lease_agreement_id: lease_agreement_id)
    self
  end

  # Filter by property
  def for_property(property_id)
    return self unless property_id.present?
    
    @relation = @relation
      .joins(:lease_agreement)
      .where(lease_agreements: { property_id: property_id })
    self
  end

  # Filter by payment status
  def with_status(status)
    return self unless status.present?
    
    statuses = Array(status)
    @relation = @relation.where(status: statuses)
    self
  end

  # Filter for pending payments
  def pending
    @relation = @relation.where(status: 'pending')
    self
  end

  # Filter for completed payments
  def completed
    @relation = @relation.where(status: 'completed')
    self
  end

  # Filter for failed payments
  def failed
    @relation = @relation.where(status: ['failed', 'error'])
    self
  end

  # Filter for overdue payments
  def overdue
    @relation = @relation
      .where(status: 'pending')
      .where("due_date < ?", Date.current)
    self
  end

  # Filter for upcoming payments
  def upcoming(days = 7)
    @relation = @relation
      .where(status: 'pending')
      .where(due_date: Date.current..(Date.current + days.days))
    self
  end

  # Filter by date range
  def between_dates(start_date, end_date)
    return self unless start_date || end_date
    
    if start_date && end_date
      @relation = @relation.where(created_at: start_date..end_date)
    elsif start_date
      @relation = @relation.where("created_at >= ?", start_date)
    elsif end_date
      @relation = @relation.where("created_at <= ?", end_date)
    end
    self
  end

  # Filter by payment type
  def of_type(payment_type)
    return self unless payment_type.present?
    
    @relation = @relation.where(payment_type: payment_type)
    self
  end

  # Filter for recurring payments
  def recurring
    @relation = @relation.where(payment_type: 'recurring')
    self
  end

  # Filter for one-time payments
  def one_time
    @relation = @relation.where(payment_type: 'one_time')
    self
  end

  # Filter by amount range
  def amount_between(min_amount, max_amount)
    @relation = @relation.where(amount: min_amount..max_amount) if min_amount && max_amount
    @relation = @relation.where("amount >= ?", min_amount) if min_amount && !max_amount
    @relation = @relation.where("amount <= ?", max_amount) if !min_amount && max_amount
    self
  end

  # Sorting methods
  def newest_first
    @relation = @relation.order(created_at: :desc)
    self
  end

  def oldest_first
    @relation = @relation.order(created_at: :asc)
    self
  end

  def by_amount_asc
    @relation = @relation.order(amount: :asc)
    self
  end

  def by_amount_desc
    @relation = @relation.order(amount: :desc)
    self
  end

  def by_due_date
    @relation = @relation.order(due_date: :asc)
    self
  end

  # Include associations
  def with_associations
    @relation = @relation.includes(
      :user,
      :payment_method,
      lease_agreement: [:property, :landlord, :tenant]
    )
    self
  end

  # Aggregation methods
  def total_amount
    @relation.sum(:amount)
  end

  def average_amount
    @relation.average(:amount)
  end

  def count_by_status
    @relation.group(:status).count
  end

  # Financial reporting
  def monthly_summary(year = Date.current.year, month = Date.current.month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    
    @relation = @relation.where(created_at: start_date..end_date)
    self
  end

  def yearly_summary(year = Date.current.year)
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)
    
    @relation = @relation.where(created_at: start_date..end_date)
    self
  end

  def revenue_by_month
    @relation
      .where(status: 'completed')
      .group("DATE_TRUNC('month', created_at)")
      .sum(:amount)
  end

  def revenue_by_property
    @relation
      .joins(lease_agreement: :property)
      .where(status: 'completed')
      .group('properties.id', 'properties.address')
      .sum(:amount)
  end

  protected

  def default_relation
    Payment.all
  end
end