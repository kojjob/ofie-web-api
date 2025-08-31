# AI-generated code: Knowledge base for Ofie rental platform bot
class KnowledgeBase
  class << self
    # Property-related knowledge
    def property_types
      {
        "apartment" => "Multi-unit residential building with shared common areas",
        "house" => "Single-family detached home with private yard",
        "condo" => "Individually owned unit in a multi-unit building",
        "townhouse" => "Multi-story home sharing walls with adjacent units",
        "studio" => "Single room living space with combined bedroom and living area",
        "loft" => "Open-plan living space, often in converted industrial buildings"
      }
    end

    def amenities_info
      {
        "parking" => "Dedicated parking space included with rental",
        "pets" => "Pet-friendly property allowing cats, dogs, or other pets",
        "furnished" => "Property comes with furniture and basic household items",
        "utilities" => "Water, electricity, gas, or internet included in rent",
        "laundry" => "In-unit or on-site laundry facilities available",
        "gym" => "Fitness center or gym access included",
        "pool" => "Swimming pool available for tenant use",
        "balcony" => "Private outdoor balcony or patio space",
        "ac" => "Air conditioning system for climate control",
        "heating" => "Central heating system for winter comfort"
      }
    end

    # Rental process knowledge
    def rental_application_process
      [
        "1. Browse available properties and find one you like",
        "2. Schedule a viewing to see the property in person",
        "3. Submit a rental application with required documents",
        "4. Wait for landlord review (typically 1-3 business days)",
        "5. If approved, review and sign the lease agreement",
        "6. Pay security deposit and first month's rent",
        "7. Receive keys and move in on the agreed date"
      ]
    end

    def required_documents
      [
        "Government-issued photo ID (driver's license or passport)",
        "Proof of income (pay stubs, employment letter, or tax returns)",
        "Bank statements (last 2-3 months)",
        "References from previous landlords or employers",
        "Credit report (some landlords may run this themselves)",
        "Proof of renters insurance (may be required before move-in)"
      ]
    end

    def income_requirements
      "Most landlords require monthly income to be 2.5-3 times the monthly rent. For example, for a $2000/month apartment, you'd need to earn $5000-$6000 per month."
    end

    # Maintenance request knowledge
    def maintenance_categories
      {
        "plumbing" => "Leaks, clogs, water pressure issues, toilet problems",
        "electrical" => "Power outages, faulty outlets, lighting issues",
        "hvac" => "Heating, cooling, ventilation problems",
        "appliances" => "Refrigerator, stove, washer, dryer issues",
        "structural" => "Doors, windows, walls, flooring problems",
        "pest_control" => "Insects, rodents, or other pest issues",
        "safety" => "Smoke detectors, locks, security concerns",
        "other" => "Any other maintenance needs not listed above"
      }
    end

    def emergency_vs_routine
      {
        emergency: [
          "No heat in winter (below 55°F)",
          "No hot water",
          "Major water leaks or flooding",
          "Electrical hazards or power outages",
          "Broken locks or security issues",
          "Gas leaks",
          "Broken windows or doors that won't lock"
        ],
        routine: [
          "Minor leaks or drips",
          "Appliance maintenance",
          "Paint touch-ups",
          "Light bulb replacements",
          "Clogged drains (non-emergency)",
          "Cosmetic repairs"
        ]
      }
    end

    # Payment knowledge
    def payment_methods
      [
        "Online payment through the platform (recommended)",
        "Bank transfer or ACH payment",
        "Credit or debit card (may include processing fees)",
        "Check or money order (if accepted by landlord)",
        "Cash payments (rarely accepted, not recommended)"
      ]
    end

    def late_payment_info
      "Rent is typically due on the 1st of each month. Late fees may apply after a grace period (usually 3-5 days). Check your lease agreement for specific terms. Contact your landlord immediately if you'll be late with payment."
    end

    # Platform navigation help
    def platform_features
      {
        "search" => "Use filters to find properties by location, price, bedrooms, amenities",
        "favorites" => "Save properties you like for easy access later",
        "applications" => "Track your rental applications and their status",
        "messages" => "Communicate directly with landlords about properties",
        "viewings" => "Schedule and manage property viewing appointments",
        "payments" => "Make rent payments and track payment history",
        "maintenance" => "Submit and track maintenance requests",
        "documents" => "Store and share rental documents securely"
      }
    end

    # Common FAQs
    def faqs
      {
        "How do I search for properties?" => "Use the search bar and filters on the main page to find properties by location, price range, number of bedrooms, and amenities.",
        "Can I schedule a viewing?" => 'Yes! Click the "Schedule Viewing" button on any property listing to request a viewing time with the landlord.',
        "How long does application review take?" => "Most landlords review applications within 1-3 business days. You'll receive a notification when there's an update.",
        "What if my application is rejected?" => "Don't worry! You can apply to other properties. Consider asking for feedback to improve future applications.",
        "How do I pay rent?" => 'Use the "Payments" section in your dashboard to set up online payments. You can pay by bank transfer or card.',
        "What if I have a maintenance emergency?" => "Submit an emergency maintenance request immediately and contact your landlord directly if it's a safety issue.",
        "Can I have pets?" => 'Look for "Pet Friendly" properties in your search. Each landlord has different pet policies and may charge pet deposits.',
        "How much security deposit is required?" => "Security deposits typically range from one to two months' rent, depending on the property and local laws."
      }
    end

    # Helpful tips
    def tenant_tips
      [
        "Read your lease agreement carefully before signing",
        "Document the property condition with photos at move-in",
        "Keep records of all communications with your landlord",
        "Pay rent on time to maintain a good rental history",
        "Report maintenance issues promptly to prevent bigger problems",
        "Get renters insurance to protect your belongings",
        "Know your rights as a tenant in your state/province",
        "Give proper notice before moving out (usually 30 days)"
      ]
    end

    def landlord_tips
      [
        "Screen tenants thoroughly with applications and references",
        "Keep properties well-maintained to attract quality tenants",
        "Respond to maintenance requests promptly",
        "Document everything for legal protection",
        "Know local landlord-tenant laws and regulations",
        "Consider professional property management for multiple units",
        "Set competitive but fair rental prices",
        "Maintain good communication with tenants"
      ]
    end
  end
end
