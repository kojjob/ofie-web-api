FactoryBot.define do
  factory :lease_agreement do
    landlord { association :user, :landlord }
    tenant { association :user, :tenant }
    association :property
    association :rental_application

    monthly_rent { Faker::Number.between(from: 1000, to: 5000) }
    security_deposit_amount { monthly_rent }
    lease_start_date { Date.current + 1.month }
    lease_end_date { Date.current + 13.months }
    status { "draft" }
    lease_number { nil } # Will be auto-generated

    trait :draft do
      status { "draft" }
    end

    trait :pending_signatures do
      status { "pending_signatures" }
    end

    trait :signed do
      status { "signed" }
      tenant_signed_at { Time.current - 2.days }
      landlord_signed_at { Time.current - 1.day }
    end

    trait :active do
      status { "active" }
      tenant_signed_at { Time.current - 1.month }
      landlord_signed_at { Time.current - 1.month }
      lease_start_date { Date.current - 15.days }
    end

    trait :terminated do
      status { "terminated" }
      termination_date { Date.current }
      termination_reason { "Lease violation" }
    end

    trait :expired do
      status { "expired" }
      lease_start_date { Date.current - 13.months }
      lease_end_date { Date.current - 1.month }
    end

    trait :tenant_signed do
      tenant_signed_at { Time.current }
    end

    trait :landlord_signed do
      landlord_signed_at { Time.current }
    end

    trait :fully_signed do
      tenant_signed
      landlord_signed
      status { "signed" }
    end

    trait :expiring_soon do
      lease_end_date { Date.current + 20.days }
    end
  end
end
