FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { :tenant }
    email_verified { false }
    phone { Faker::PhoneNumber.phone_number }
    bio { Faker::Lorem.paragraph }
    language { %w[en es fr].sample }
    timezone { "UTC" }

    trait :landlord do
      role { :landlord }
    end

    trait :tenant do
      role { :tenant }
    end

    trait :bot do
      role { :bot }
    end

    trait :verified do
      email_verified { true }
    end

    trait :oauth_user do
      provider { "google" }
      uid { Faker::Alphanumeric.alphanumeric(number: 20) }
      email_verified { true }
      password { nil }
      password_confirmation { nil }
    end

    trait :with_stripe do
      stripe_customer_id { "cus_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
    end

    trait :with_refresh_token do
      refresh_token { SecureRandom.hex(32) }
      refresh_token_expires_at { 30.days.from_now }
    end

    trait :with_password_reset do
      password_reset_token { SecureRandom.urlsafe_base64(32) }
      password_reset_sent_at { Time.current }
    end

    trait :with_email_verification do
      email_verification_token { SecureRandom.urlsafe_base64(32) }
      email_verification_sent_at { Time.current }
    end
  end
end
