# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data in development
if Rails.env.development?
  Property.destroy_all
  User.destroy_all
end

# Create sample users
puts "Creating sample users..."

# Create landlords
lanlord1 = User.create!(
  email: 'landlord1@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: 'landlord'
)

lanlord2 = User.create!(
  email: 'landlord2@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: 'landlord'
)

# Create tenants
tenant1 = User.create!(
  email: 'tenant1@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: 'tenant'
)

tenant2 = User.create!(
  email: 'tenant2@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: 'tenant'
)

puts "Created #{User.count} users"

# Create sample properties
puts "Creating sample properties..."

properties_data = [
  {
    title: 'Modern Downtown Apartment',
    description: 'Beautiful 2-bedroom apartment in the heart of downtown with stunning city views. Features include hardwood floors, stainless steel appliances, and in-unit laundry.',
    address: '123 Main Street, Apt 4B',
    city: 'San Francisco',
    state: 'CA',
    zip_code: '94102',
    price: 3500.00,
    bedrooms: 2,
    bathrooms: 2.0,
    square_feet: 1200,
    property_type: 'apartment',
    available: true,
    user: lanlord1
  },
  {
    title: 'Cozy Studio Near University',
    description: 'Perfect for students! This cozy studio is just a 5-minute walk from the university campus. Includes all utilities and high-speed internet.',
    address: '456 College Avenue',
    city: 'Berkeley',
    state: 'CA',
    zip_code: '94704',
    price: 1800.00,
    bedrooms: 0,
    bathrooms: 1.0,
    square_feet: 500,
    property_type: 'studio',
    available: true,
    user: lanlord1
  },
  {
    title: 'Spacious Family House',
    description: 'Large 4-bedroom house perfect for families. Features a big backyard, 2-car garage, and updated kitchen. Located in a quiet neighborhood with great schools.',
    address: '789 Oak Street',
    city: 'Palo Alto',
    state: 'CA',
    zip_code: '94301',
    price: 6500.00,
    bedrooms: 4,
    bathrooms: 3.5,
    square_feet: 2800,
    property_type: 'house',
    available: true,
    user: lanlord2
  },
  {
    title: 'Luxury Condo with Bay Views',
    description: 'Stunning 3-bedroom condo with panoramic bay views. Premium finishes throughout, including marble countertops and floor-to-ceiling windows.',
    address: '321 Bay Street, Unit 15A',
    city: 'San Francisco',
    state: 'CA',
    zip_code: '94133',
    price: 5200.00,
    bedrooms: 3,
    bathrooms: 2.5,
    square_feet: 1800,
    property_type: 'condo',
    available: true,
    user: lanlord2
  },
  {
    title: 'Charming Townhouse',
    description: 'Beautiful 3-bedroom townhouse with private patio and attached garage. Recently renovated with modern amenities while maintaining classic charm.',
    address: '654 Elm Street',
    city: 'San Jose',
    state: 'CA',
    zip_code: '95110',
    price: 4200.00,
    bedrooms: 3,
    bathrooms: 2.5,
    square_feet: 1600,
    property_type: 'townhouse',
    available: false,
    user: lanlord1
  }
]

properties_data.each do |property_data|
  Property.create!(property_data)
end

puts "Created #{Property.count} properties"
puts "Seed data created successfully!"
puts ""
puts "Sample login credentials:"
puts "Landlord 1: landlord1@example.com / password123"
puts "Landlord 2: landlord2@example.com / password123"
puts "Tenant 1: tenant1@example.com / password123"
puts "Tenant 2: tenant2@example.com / password123"
