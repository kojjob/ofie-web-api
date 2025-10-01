FactoryBot.define do
  factory :message do
    association :conversation
    association :sender, factory: :user

    content { "This is a test message about the property." }
    message_type { "text" }
    read { false }
    read_at { nil }

    trait :read do
      read { true }
      read_at { Time.current }
    end

    trait :image do
      message_type { "image" }
      content { "Image description or URL" }
    end

    trait :file do
      message_type { "file" }
      content { "File description or URL" }
    end
  end
end
