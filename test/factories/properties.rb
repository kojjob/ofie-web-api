FactoryBot.define do
  factory :property do
    association :user, factory: :user, role: :landlord
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 5) }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    price { Faker::Number.between(from: 500, to: 5000) }
    bedrooms { Faker::Number.between(from: 1, to: 5) }
    bathrooms { Faker::Number.between(from: 1, to: 3) }
    square_feet { Faker::Number.between(from: 500, to: 3000) }
    property_type { :apartment }
    availability_status { :available }
    status { :active }

    # Amenities
    parking_available { [ true, false ].sample }
    pets_allowed { [ true, false ].sample }
    furnished { [ true, false ].sample }
    utilities_included { [ true, false ].sample }
    laundry { [ true, false ].sample }
    gym { [ true, false ].sample }
    pool { [ true, false ].sample }
    balcony { [ true, false ].sample }
    air_conditioning { true }
    heating { true }
    internet_included { [ true, false ].sample }

    # Location
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }

    trait :house do
      property_type { :house }
      bedrooms { Faker::Number.between(from: 3, to: 5) }
      bathrooms { Faker::Number.between(from: 2, to: 4) }
      square_feet { Faker::Number.between(from: 1500, to: 4000) }
    end

    trait :condo do
      property_type { :condo }
    end

    trait :townhouse do
      property_type { :townhouse }
      bedrooms { Faker::Number.between(from: 2, to: 4) }
    end

    trait :studio do
      property_type { :studio }
      bedrooms { 0 }
      bathrooms { 1 }
      square_feet { Faker::Number.between(from: 300, to: 600) }
    end

    trait :loft do
      property_type { :loft }
      bedrooms { Faker::Number.between(from: 1, to: 2) }
    end

    trait :available do
      availability_status { :available }
      status { :active }
    end

    trait :rented do
      availability_status { :rented }
    end

    trait :pending do
      availability_status { :pending }
    end

    trait :maintenance do
      availability_status { :maintenance }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :draft do
      status { :draft }
    end

    trait :archived do
      status { :archived }
    end

    trait :with_parking do
      parking_available { true }
    end

    trait :pet_friendly do
      pets_allowed { true }
    end

    trait :furnished do
      furnished { true }
    end

    trait :utilities_included do
      utilities_included { true }
    end

    trait :luxury do
      price { Faker::Number.between(from: 3000, to: 10000) }
      square_feet { Faker::Number.between(from: 2000, to: 5000) }
      gym { true }
      pool { true }
      parking_available { true }
      balcony { true }
    end
  end
end
