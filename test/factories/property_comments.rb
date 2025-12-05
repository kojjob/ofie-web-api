FactoryBot.define do
  factory :property_comment do
    user
    property
    content { Faker::Lorem.paragraph(sentence_count: 2) }
    edited { false }
    flagged { false }

    trait :with_parent do
      association :parent, factory: :property_comment
    end

    trait :edited do
      edited { true }
      edited_at { 1.hour.ago }
    end

    trait :flagged do
      flagged { true }
      flagged_reason { "Inappropriate content" }
      flagged_at { 1.hour.ago }
    end
  end
end
