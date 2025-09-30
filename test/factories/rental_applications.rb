FactoryBot.define do
  factory :rental_application do
    tenant { association :user, :tenant }
    association :property
    reviewed_by { nil }

    move_in_date { Date.current + 1.month }
    status { "pending" }
    employment_status { "employed" }
    monthly_income { (property&.price || 2000) * 3.5 }  # Ensure sufficient income (3.5x rent)
    previous_address { Faker::Address.full_address }
    references_contact { Faker::PhoneNumber.cell_phone }
    additional_notes { Faker::Lorem.paragraph }

    trait :pending do
      status { "pending" }
    end

    trait :under_review do
      status { "under_review" }
    end

    trait :approved do
      status { "approved" }
      reviewed_by { association :user, :landlord }
      reviewed_at { Time.current }
    end

    trait :rejected do
      status { "rejected" }
      reviewed_by { association :user, :landlord }
      reviewed_at { Time.current }
      rejection_reason { "Insufficient income verification" }
    end

    trait :withdrawn do
      status { "withdrawn" }
    end
  end
end
