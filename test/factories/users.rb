FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    full_name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    user_type { "individual" }
    email_verified { true }
    email_verified_at { Time.current }

    trait :unverified do
      email_verified { false }
      email_verified_at { nil }
    end

    trait :admin do
      user_type { "admin" }
    end

    trait :agent do
      user_type { "agent" }
      company_name { Faker::Company.name }
    end

    trait :landlord do
      user_type { "landlord" }
    end

    trait :with_profile_image do
      after(:create) do |user|
        user.profile_image.attach(
          io: File.open(Rails.root.join("test/fixtures/files/sample_avatar.jpg")),
          filename: "avatar.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end
