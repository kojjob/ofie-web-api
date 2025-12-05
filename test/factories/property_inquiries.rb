FactoryBot.define do
  factory :property_inquiry do
    association :property
    association :user, factory: :user, role: :tenant
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { "+1#{Faker::Number.number(digits: 10)}" }
    message { Faker::Lorem.paragraph(sentence_count: 3) }
    status { :pending }
    gdpr_consent { true }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" }
    read_at { nil }

    trait :pending do
      status { :pending }
      read_at { nil }
    end

    trait :read do
      status { :read }
      read_at { 1.hour.ago }
    end

    trait :responded do
      status { :responded }
      read_at { 2.hours.ago }
    end

    trait :archived do
      status { :archived }
      read_at { 1.day.ago }
    end

    trait :anonymous do
      user { nil }
    end

    trait :recent do
      created_at { 1.day.ago }
    end

    trait :old do
      created_at { 2.weeks.ago }
    end
  end
end
