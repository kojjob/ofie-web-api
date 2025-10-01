FactoryBot.define do
  factory :notification do
    association :user

    title { "Test Notification" }
    message { "This is a test notification message." }
    notification_type { "system" }
    url { "/test" }
    read { false }
    read_at { nil }

    trait :read do
      read { true }
      read_at { Time.current }
    end

    trait :with_maintenance_request do
      association :notifiable, factory: :maintenance_request
      notification_type { "maintenance_request_new" }
      title { "New Maintenance Request" }
      message { "A new maintenance request has been submitted" }
      url { |n| "/maintenance_requests/#{n.notifiable.id}" }
    end

    trait :with_rental_application do
      association :notifiable, factory: :rental_application
      notification_type { "rental_application_new" }
      title { "New Rental Application" }
      message { "A new rental application has been submitted" }
      url { |n| "/rental_applications/#{n.notifiable.id}" }
    end

    trait :with_property do
      association :notifiable, factory: :property
      notification_type { "property_update" }
      title { "Property Updated" }
      message { "Your property has been updated" }
      url { |n| "/properties/#{n.notifiable.id}" }
    end

    trait :favorite do
      notification_type { "favorite" }
      title { "Property Favorited" }
      message { "Someone favorited your property" }
    end

    trait :message do
      notification_type { "message" }
      title { "New Message" }
      message { "You have a new message" }
      url { "/messages" }
    end

    trait :payment do
      notification_type { "payment" }
      title { "Payment Received" }
      message { "A payment has been received" }
      url { "/payments" }
    end

    trait :maintenance_status_change do
      association :notifiable, factory: :maintenance_request
      notification_type { "maintenance_request_status_change" }
      title { "Maintenance Request Updated" }
      message { "Your maintenance request status has been updated" }
      url { |n| "/maintenance_requests/#{n.notifiable.id}" }
    end

    trait :application_status_change do
      association :notifiable, factory: :rental_application
      notification_type { "rental_application_status_change" }
      title { "Application Status Updated" }
      message { "Your application status has been updated" }
      url { |n| "/rental_applications/#{n.notifiable.id}" }
    end
  end
end
