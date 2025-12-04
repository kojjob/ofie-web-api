FactoryBot.define do
  factory :maintenance_request do
    association :property
    tenant { association :user, :tenant }
    landlord { association :user, :landlord }

    title { Faker::Lorem.sentence(word_count: 5) }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    category { "plumbing" }
    priority { "medium" }
    status { "pending" }

    trait :plumbing do
      category { "plumbing" }
      title { "Leaking faucet in bathroom" }
    end

    trait :electrical do
      category { "electrical" }
      title { "Flickering lights in living room" }
    end

    trait :hvac do
      category { "hvac" }
      title { "Air conditioning not working" }
    end

    trait :appliance do
      category { "appliance" }
      title { "Refrigerator not cooling properly" }
    end

    trait :structural do
      category { "structural" }
      title { "Crack in ceiling" }
    end

    trait :pest_control do
      category { "pest_control" }
      title { "Rodent infestation" }
    end

    trait :other do
      category { "other" }
      title { "General maintenance issue" }
    end

    trait :low_priority do
      priority { "low" }
    end

    trait :medium_priority do
      priority { "medium" }
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :urgent do
      priority { "urgent" }
    end

    trait :pending do
      status { "pending" }
    end

    trait :in_progress do
      status { "in_progress" }
      assigned_to { association :user, :landlord }
      assigned_at { Time.current }
    end

    trait :completed do
      status { "completed" }
      assigned_to { association :user, :landlord }
      assigned_at { Time.current - 2.days }
      completed_at { Time.current }
    end

    trait :canceled do
      status { "canceled" }
      cancellation_reason { "Issue resolved by tenant" }
    end

    trait :with_assigned_to do
      assigned_to { association :user, :landlord }
      assigned_at { Time.current }
    end
  end
end
