FactoryBot.define do
  factory :property do
    association :user
    title { Faker::Lorem.sentence(word_count: 4) }
    description { Faker::Lorem.paragraph(sentence_count: 5) }
    price { Faker::Number.between(from: 50000, to: 1000000) }
    bedrooms { Faker::Number.between(from: 1, to: 6) }
    bathrooms { Faker::Number.between(from: 1, to: 4) }
    area { Faker::Number.between(from: 500, to: 5000) }
    property_type { %w[apartment house condo townhouse villa].sample }
    listing_type { %w[sale rent].sample }
    status { "available" }
    
    # Address fields
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    country { "USA" }
    postal_code { Faker::Address.zip_code }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    
    # Features
    features { ["parking", "swimming_pool", "gym", "security"].sample(2) }
    
    trait :sold do
      status { "sold" }
    end
    
    trait :rented do
      status { "rented" }
      listing_type { "rent" }
    end
    
    trait :pending do
      status { "pending" }
    end
    
    trait :with_photos do
      after(:create) do |property|
        3.times do |i|
          property.photos.attach(
            io: File.open(Rails.root.join("test/fixtures/files/property_#{i + 1}.jpg")),
            filename: "property_#{i + 1}.jpg",
            content_type: 'image/jpeg'
          )
        end
      end
    end
    
    trait :featured do
      featured { true }
    end
    
    trait :with_virtual_tour do
      virtual_tour_url { "https://example.com/virtual-tour/#{Faker::Alphanumeric.alphanumeric(number: 10)}" }
    end
  end
end