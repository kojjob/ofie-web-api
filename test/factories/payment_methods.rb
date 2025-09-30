FactoryBot.define do
  factory :payment_method do
    association :user

    stripe_payment_method_id { "pm_#{Faker::Alphanumeric.alphanumeric(number: 24)}" }
    payment_type { "card" }
    last_four { Faker::Number.number(digits: 4).to_s }
    brand { %w[visa mastercard amex discover].sample }
    exp_month { rand(1..12) }
    exp_year { Date.current.year + rand(1..5) }
    is_default { false }

    trait :default do
      is_default { true }
    end

    trait :card do
      payment_type { "card" }
    end

    trait :bank_account do
      payment_type { "bank_account" }
      brand { nil }
      last_four { Faker::Number.number(digits: 4).to_s }
    end
  end
end
