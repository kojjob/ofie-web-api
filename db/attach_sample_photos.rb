# Script to attach sample photos to existing properties
# Run with: rails runner db/attach_sample_photos.rb

require 'open-uri'

# Sample property images from Unsplash (free to use)
sample_images = [
  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop', # Modern apartment
  'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&h=600&fit=crop', # Cozy interior
  'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&h=600&fit=crop', # Kitchen
  'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&h=600&fit=crop', # Living room
  'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&h=600&fit=crop', # Bedroom
  'https://images.unsplash.com/photo-1571624436279-b272aff752b5?w=800&h=600&fit=crop', # Bathroom
  'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800&h=600&fit=crop', # House exterior
  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&h=600&fit=crop', # Modern house
  'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&h=600&fit=crop', # Apartment building
  'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=600&fit=crop'  # Beautiful home
]

def attach_photos_to_properties(sample_images)
  puts "Starting to attach photos to properties..."

  Property.find_each.with_index do |property, index|
    next if property.photos.attached?

    puts "Attaching photos to property: #{property.title}"

    # Attach 2-4 random photos per property
    num_photos = rand(2..4)
    selected_images = sample_images.sample(num_photos)

    selected_images.each_with_index do |image_url, photo_index|
      begin
        # Download and attach the image
        image_data = URI.open(image_url)
        filename = "property_#{property.id}_photo_#{photo_index + 1}.jpg"

        property.photos.attach(
          io: image_data,
          filename: filename,
          content_type: 'image/jpeg'
        )

        puts "  ✓ Attached photo #{photo_index + 1}/#{num_photos}"

        # Small delay to avoid overwhelming the API
        sleep(0.5)

      rescue => e
        puts "  ✗ Failed to attach photo #{photo_index + 1}: #{e.message}"
      end
    end

    puts "  Completed property #{index + 1}/#{Property.count}"
    puts ""
  end

  puts "Photo attachment completed!"
  puts "Properties with photos: #{Property.joins(:photos_attachments).distinct.count}/#{Property.count}"
end

# Alternative method using local placeholder images if internet is not available
def create_placeholder_images
  puts "Creating placeholder images for properties..."

  # Create a simple SVG placeholder
  placeholder_svg = <<~SVG
    <svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">
      <rect width="100%" height="100%" fill="#f3f4f6"/>
      <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="24" fill="#6b7280" text-anchor="middle" dy=".3em">Property Image</text>
    </svg>
  SVG

  Property.find_each.with_index do |property, index|
    next if property.photos.attached?

    puts "Creating placeholder for property: #{property.title}"

    # Create 2-3 placeholder images per property
    num_photos = rand(2..3)

    num_photos.times do |photo_index|
      filename = "property_#{property.id}_placeholder_#{photo_index + 1}.svg"

      property.photos.attach(
        io: StringIO.new(placeholder_svg),
        filename: filename,
        content_type: 'image/svg+xml'
      )
    end

    puts "  ✓ Created #{num_photos} placeholder images"
  end

  puts "Placeholder creation completed!"
end

# Run the photo attachment
begin
  attach_photos_to_properties(sample_images)
rescue => e
  puts "Failed to download images from internet: #{e.message}"
  puts "Falling back to placeholder images..."
  create_placeholder_images
end
