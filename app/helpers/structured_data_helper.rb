# Structured Data Helper Module
# Provides comprehensive structured data generation for various content types
module StructuredDataHelper
  # Generate complete structured data for a property listing
  def property_listing_structured_data(property)
    {
      "@context": "https://schema.org",
      "@type": "RealEstateListing",
      "@id": property_url(property),
      "name": property.title,
      "description": meta_truncate(property.description, 300),
      "url": property_url(property),
      "datePosted": property.created_at.iso8601,
      "dateModified": property.updated_at.iso8601,
      "tourBookingPage": new_property_viewing_url(property),

      # Property details
      "propertyID": property.id,
      "yearBuilt": property.year_built,
      "petsAllowed": property.pet_friendly?,
      "smokingAllowed": property.smoking_allowed?,
      "numberOfRooms": property.bedrooms,
      "numberOfBathroomsTotal": property.bathrooms,
      "accommodationCategory": property.property_type&.capitalize,

      # Pricing information
      "offers": {
        "@type": "Offer",
        "price": property.price,
        "priceCurrency": "USD",
        "priceValidUntil": (Date.today + 30.days).iso8601,
        "availability": property_availability_schema(property),
        "validFrom": property.created_at.iso8601
      },

      # Location information
      "address": property_address_schema(property),
      "geo": property_geo_schema(property),

      # Size information
      "floorSize": {
        "@type": "QuantitativeValue",
        "value": property.square_feet,
        "unitCode": "FTK",
        "unitText": "square feet"
      },

      # Amenities
      "amenityFeature": property_amenities_schema(property),

      # Images
      "image": property_images_schema(property),
      "photo": property_images_schema(property),

      # Additional details
      "additionalProperty": property_additional_features(property),

      # Agent/Owner information
      "seller": property_seller_schema(property),

      # Reviews if available
      "review": property_reviews_schema(property),
      "aggregateRating": property_rating_schema(property)
    }.compact
  end

  # Generate address structured data
  def property_address_schema(property)
    {
      "@type": "PostalAddress",
      "streetAddress": property.address,
      "addressLocality": property.city,
      "addressRegion": property.state,
      "postalCode": property.zip_code,
      "addressCountry": "US"
    }
  end

  # Generate geo coordinates structured data
  def property_geo_schema(property)
    return nil unless property.latitude.present? && property.longitude.present?

    {
      "@type": "GeoCoordinates",
      "latitude": property.latitude,
      "longitude": property.longitude
    }
  end

  # Generate availability schema
  def property_availability_schema(property)
    if property.available?
      "https://schema.org/InStock"
    elsif property.under_contract?
      "https://schema.org/PreOrder"
    else
      "https://schema.org/OutOfStock"
    end
  end

  # Generate amenities structured data
  def property_amenities_schema(property)
    amenities = []

    amenities << { "@type": "LocationFeatureSpecification", "name": "Parking", "value": true } if property.parking
    amenities << { "@type": "LocationFeatureSpecification", "name": "Laundry", "value": true } if property.laundry
    amenities << { "@type": "LocationFeatureSpecification", "name": "Gym", "value": true } if property.gym
    amenities << { "@type": "LocationFeatureSpecification", "name": "Pool", "value": true } if property.pool
    amenities << { "@type": "LocationFeatureSpecification", "name": "Elevator", "value": true } if property.elevator
    amenities << { "@type": "LocationFeatureSpecification", "name": "Balcony", "value": true } if property.balcony
    amenities << { "@type": "LocationFeatureSpecification", "name": "Pet Friendly", "value": true } if property.pet_friendly

    amenities
  end

  # Generate images structured data
  def property_images_schema(property)
    return [] unless property.images.attached?

    property.images.map do |image|
      {
        "@type": "ImageObject",
        "url": url_for(image),
        "contentUrl": url_for(image),
        "caption": property.title
      }
    end
  end

  # Generate additional property features
  def property_additional_features(property)
    features = []

    if property.furnished?
      features << {
        "@type": "PropertyValue",
        "name": "Furnished",
        "value": "Yes"
      }
    end

    if property.utilities_included?
      features << {
        "@type": "PropertyValue",
        "name": "Utilities Included",
        "value": "Yes"
      }
    end

    features
  end

  # Generate seller/agent structured data
  def property_seller_schema(property)
    return nil unless property.user.present?

    {
      "@type": "Person",
      "name": property.user.full_name,
      "email": property.user.email,
      "telephone": property.user.phone_number
    }
  end

  # Generate reviews structured data
  def property_reviews_schema(property)
    return [] unless property.reviews.published.any?

    property.reviews.published.limit(5).map do |review|
      {
        "@type": "Review",
        "author": {
          "@type": "Person",
          "name": review.user.full_name
        },
        "datePublished": review.created_at.iso8601,
        "reviewBody": review.comment,
        "reviewRating": {
          "@type": "Rating",
          "ratingValue": review.rating,
          "bestRating": 5,
          "worstRating": 1
        }
      }
    end
  end

  # Generate aggregate rating structured data
  def property_rating_schema(property)
    return nil unless property.reviews.published.any?

    {
      "@type": "AggregateRating",
      "ratingValue": property.average_rating,
      "bestRating": 5,
      "worstRating": 1,
      "ratingCount": property.reviews_count
    }
  end

  # Generate search results page structured data
  def search_results_structured_data(properties)
    {
      "@context": "https://schema.org",
      "@type": "ItemList",
      "itemListElement": properties.map.with_index do |property, index|
        {
          "@type": "ListItem",
          "position": index + 1,
          "url": property_url(property),
          "name": property.title,
          "image": property.images.first ? url_for(property.images.first) : nil
        }
      end
    }
  end

  # Generate event structured data for open houses
  def open_house_structured_data(property, event_date)
    {
      "@context": "https://schema.org",
      "@type": "Event",
      "name": "Open House: #{property.title}",
      "startDate": event_date.iso8601,
      "endDate": (event_date + 2.hours).iso8601,
      "location": {
        "@type": "Place",
        "name": property.title,
        "address": property_address_schema(property)
      },
      "description": "Open house viewing for #{property.title}",
      "organizer": property_seller_schema(property),
      "eventStatus": "https://schema.org/EventScheduled",
      "eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode",
      "offers": {
        "@type": "Offer",
        "price": "0",
        "priceCurrency": "USD",
        "availability": "https://schema.org/InStock"
      }
    }
  end

  # Generate Q&A structured data
  def qa_structured_data(questions)
    {
      "@context": "https://schema.org",
      "@type": "QAPage",
      "mainEntity": questions.map do |q|
        {
          "@type": "Question",
          "name": q[:question],
          "text": q[:question],
          "answerCount": q[:answers].count,
          "acceptedAnswer": q[:answers].first ? {
            "@type": "Answer",
            "text": q[:answers].first[:text],
            "dateCreated": q[:answers].first[:date],
            "author": {
              "@type": "Person",
              "name": q[:answers].first[:author]
            }
          } : nil
        }.compact
      end
    }
  end

  # Generate how-to structured data for guides
  def how_to_structured_data(title, description, steps)
    {
      "@context": "https://schema.org",
      "@type": "HowTo",
      "name": title,
      "description": description,
      "step": steps.map.with_index do |step, index|
        {
          "@type": "HowToStep",
          "position": index + 1,
          "name": step[:title],
          "text": step[:description],
          "url": step[:url]
        }.compact
      end
    }
  end

  # Generate video structured data
  def video_structured_data(video)
    {
      "@context": "https://schema.org",
      "@type": "VideoObject",
      "name": video[:title],
      "description": video[:description],
      "thumbnailUrl": video[:thumbnail_url],
      "uploadDate": video[:upload_date],
      "duration": video[:duration],
      "contentUrl": video[:url],
      "embedUrl": video[:embed_url]
    }
  end
end

