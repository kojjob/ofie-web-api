FactoryBot.define do
  factory :payment_schedule do
    association :lease_agreement

    payment_type { "rent" }
    amount { lease_agreement&.monthly_rent || 1500.00 }
    frequency { "monthly" }
    start_date { Date.current }
    end_date { Date.current + 12.months }
    next_payment_date { Date.current }
    is_active { true }
    auto_pay { false }
    day_of_month { start_date.day }
    description { "Monthly rent payment" }
    metadata { {} }

    trait :auto_pay do
      auto_pay { true }
    end

    trait :inactive do
      is_active { false }
    end

    trait :security_deposit do
      payment_type { "security_deposit" }
      frequency { "one_time" }
      description { "Security deposit payment" }
      amount { lease_agreement&.security_deposit_amount || 1500.00 }
    end

    trait :utility do
      payment_type { "utility" }
      description { "Monthly utility payment" }
      amount { 150.00 }
    end
  end
end
