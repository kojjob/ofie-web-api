FactoryBot.define do
  factory :payment do
    association :lease_agreement
    association :user, factory: [:user, :tenant]

    amount { Faker::Number.between(from: 500, to: 5000) }
    payment_type { "rent" }
    status { "pending" }
    due_date { Date.current + 5.days }
    payment_number { nil } # Will be auto-generated
    description { nil } # Will be auto-generated based on payment_type

    trait :rent do
      payment_type { "rent" }
      amount { lease_agreement&.monthly_rent || 1500 }
    end

    trait :security_deposit do
      payment_type { "security_deposit" }
      amount { lease_agreement&.security_deposit_amount || 1500 }
      due_date { lease_agreement&.lease_start_date || Date.current }
    end

    trait :late_fee do
      payment_type { "late_fee" }
      amount { Faker::Number.between(from: 50, to: 200) }
    end

    trait :utility do
      payment_type { "utility" }
      amount { Faker::Number.between(from: 50, to: 300) }
    end

    trait :maintenance_fee do
      payment_type { "maintenance_fee" }
      amount { Faker::Number.between(from: 100, to: 500) }
    end

    trait :other do
      payment_type { "other" }
      amount { Faker::Number.between(from: 50, to: 500) }
    end

    trait :pending do
      status { "pending" }
    end

    trait :processing do
      status { "processing" }
    end

    trait :succeeded do
      status { "succeeded" }
      paid_at { Time.current }
      stripe_charge_id { "ch_#{Faker::Alphanumeric.alphanumeric(number: 24)}" }
    end

    trait :failed do
      status { "failed" }
      failure_reason { "Insufficient funds" }
    end

    trait :canceled do
      status { "canceled" }
    end

    trait :refunded do
      status { "refunded" }
      paid_at { Time.current - 10.days }
      stripe_charge_id { "ch_#{Faker::Alphanumeric.alphanumeric(number: 24)}" }
      stripe_refund_id { "re_#{Faker::Alphanumeric.alphanumeric(number: 24)}" }
    end

    trait :overdue do
      due_date { Date.current - 10.days }
      status { "pending" }
    end

    trait :due_soon do
      due_date { Date.current + 3.days }
      status { "pending" }
    end

    trait :with_payment_method do
      association :payment_method
    end
  end
end
