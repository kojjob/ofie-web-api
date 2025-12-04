FactoryBot.define do
  factory :conversation do
    association :landlord, factory: :user, role: "landlord"
    association :tenant, factory: :user, role: "tenant"
    association :property, factory: :property

    subject { property ? "Inquiry about #{property.title}" : "General inquiry" }
    status { "active" }
    last_message_at { Time.current }

    trait :archived do
      status { "archived" }
    end

    trait :closed do
      status { "closed" }
    end
  end
end
