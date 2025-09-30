FactoryBot.define do
  factory :rental_application do
    association :tenant, factory: [:user, :tenant]
    association :property
    association :reviewed_by, factory: [:user, :landlord], optional: true

    move_in_date { Date.current + 1.month }
    move_out_date { Date.current + 13.months }
    status { "pending" }
    employment_status { "employed" }
    employer_name { Faker::Company.name }
    job_title { Faker::Job.title }
    annual_income { Faker::Number.between(from: 30000, to: 150000) }
    emergency_contact_name { Faker::Name.name }
    emergency_contact_phone { Faker::PhoneNumber.phone_number }
    emergency_contact_relationship { "parent" }
    has_pets { [true, false].sample }
    has_references { true }

    trait :pending do
      status { "pending" }
    end

    trait :under_review do
      status { "under_review" }
    end

    trait :approved do
      status { "approved" }
      association :reviewed_by, factory: [:user, :landlord]
      reviewed_at { Time.current }
    end

    trait :rejected do
      status { "rejected" }
      association :reviewed_by, factory: [:user, :landlord]
      reviewed_at { Time.current }
      rejection_reason { "Insufficient income verification" }
    end

    trait :withdrawn do
      status { "withdrawn" }
    end

    trait :with_pets do
      has_pets { true }
      pet_details { "One small dog, house-trained" }
    end

    trait :with_references do
      has_references { true }
    end

    trait :employed do
      employment_status { "employed" }
    end

    trait :self_employed do
      employment_status { "self_employed" }
    end

    trait :unemployed do
      employment_status { "unemployed" }
    end

    trait :student do
      employment_status { "student" }
    end
  end
end
