FactoryBot.define do
  factory :property_viewing do
    association :user, factory: :user
    association :property, factory: :property
    scheduled_at { 3.days.from_now }
    status { 0 }  # pending
    viewing_type { 0 }  # in_person
    contact_email { Faker::Internet.email }
    contact_phone { "+15555551234" }
  end
end
