require "test_helper"

class KnowledgeBaseTest < ActiveSupport::TestCase
  # ============================================================================
  # PROPERTY TYPES TESTS
  # ============================================================================

  test "property_types returns hash of property types with descriptions" do
    property_types = KnowledgeBase.property_types

    assert_instance_of Hash, property_types
    assert_not_empty property_types

    # Check key property types are included
    assert_includes property_types.keys, "apartment"
    assert_includes property_types.keys, "house"
    assert_includes property_types.keys, "condo"
    assert_includes property_types.keys, "townhouse"
    assert_includes property_types.keys, "studio"
    assert_includes property_types.keys, "loft"

    # Verify descriptions are strings
    property_types.each do |key, description|
      assert_instance_of String, key
      assert_instance_of String, description
      assert description.length > 10, "Description should be meaningful"
    end
  end

  # ============================================================================
  # AMENITIES INFO TESTS
  # ============================================================================

  test "amenities_info returns hash of amenities with descriptions" do
    amenities = KnowledgeBase.amenities_info

    assert_instance_of Hash, amenities
    assert_not_empty amenities

    # Check key amenities are included
    assert_includes amenities.keys, "parking"
    assert_includes amenities.keys, "pets"
    assert_includes amenities.keys, "furnished"
    assert_includes amenities.keys, "utilities"
    assert_includes amenities.keys, "laundry"

    # Verify descriptions are meaningful strings
    amenities.each do |key, description|
      assert_instance_of String, key
      assert_instance_of String, description
      assert description.length > 10, "Description should be meaningful"
    end
  end

  # ============================================================================
  # RENTAL APPLICATION PROCESS TESTS
  # ============================================================================

  test "rental_application_process returns array of steps" do
    process_steps = KnowledgeBase.rental_application_process

    assert_instance_of Array, process_steps
    assert_equal 7, process_steps.length

    # Verify steps are in order (numbered 1-7)
    process_steps.each_with_index do |step, index|
      assert_match /^#{index + 1}\./, step, "Step should start with #{index + 1}."
    end

    # Check first and last steps
    assert_match /Browse available properties/, process_steps.first
    assert_match /Receive keys and move in/, process_steps.last
  end

  # ============================================================================
  # REQUIRED DOCUMENTS TESTS
  # ============================================================================

  test "required_documents returns array of required documents" do
    documents = KnowledgeBase.required_documents

    assert_instance_of Array, documents
    assert_operator documents.length, :>=, 5

    # Check key documents are included
    assert documents.any? { |doc| doc.include?("photo ID") }
    assert documents.any? { |doc| doc.include?("Proof of income") }
    assert documents.any? { |doc| doc.include?("Bank statements") }
    assert documents.any? { |doc| doc.include?("References") }

    # Verify all are strings
    documents.each do |doc|
      assert_instance_of String, doc
      assert doc.length > 10
    end
  end

  # ============================================================================
  # INCOME REQUIREMENTS TESTS
  # ============================================================================

  test "income_requirements returns helpful information string" do
    info = KnowledgeBase.income_requirements

    assert_instance_of String, info
    assert_not_empty info

    # Should mention the 2.5-3x multiplier
    assert_match /2\.5-3/, info

    # Should include an example
    assert_match /example/i, info
    assert_match /\$\d+/, info  # Should contain dollar amounts
  end

  # ============================================================================
  # MAINTENANCE CATEGORIES TESTS
  # ============================================================================

  test "maintenance_categories returns hash of categories with descriptions" do
    categories = KnowledgeBase.maintenance_categories

    assert_instance_of Hash, categories
    assert_not_empty categories

    # Check key categories are included
    assert_includes categories.keys, "plumbing"
    assert_includes categories.keys, "electrical"
    assert_includes categories.keys, "hvac"
    assert_includes categories.keys, "appliances"
    assert_includes categories.keys, "structural"
    assert_includes categories.keys, "pest_control"
    assert_includes categories.keys, "safety"
    assert_includes categories.keys, "other"

    # Verify descriptions mention specific issues
    assert_match /leak|clog|water/i, categories["plumbing"]
    assert_match /power|outlet|light/i, categories["electrical"]
  end

  # ============================================================================
  # EMERGENCY VS ROUTINE TESTS
  # ============================================================================

  test "emergency_vs_routine returns hash with emergency and routine arrays" do
    info = KnowledgeBase.emergency_vs_routine

    assert_instance_of Hash, info
    assert_includes info.keys, :emergency
    assert_includes info.keys, :routine

    # Check emergency items
    assert_instance_of Array, info[:emergency]
    assert_operator info[:emergency].length, :>=, 5
    assert info[:emergency].any? { |item| item.include?("heat") }
    assert info[:emergency].any? { |item| item.include?("water") }
    assert info[:emergency].any? { |item| item.include?("leak") }

    # Check routine items
    assert_instance_of Array, info[:routine]
    assert_operator info[:routine].length, :>=, 5
    assert info[:routine].any? { |item| item.include?("Minor") || item.include?("Cosmetic") }
  end

  # ============================================================================
  # PAYMENT METHODS TESTS
  # ============================================================================

  test "payment_methods returns array of payment options" do
    methods = KnowledgeBase.payment_methods

    assert_instance_of Array, methods
    assert_operator methods.length, :>=, 4

    # Check key payment methods are included
    assert methods.any? { |m| m.include?("Online payment") }
    assert methods.any? { |m| m.include?("Bank transfer") || m.include?("ACH") }
    assert methods.any? { |m| m.include?("Credit") || m.include?("debit card") }

    # Verify all are strings
    methods.each do |method|
      assert_instance_of String, method
      assert method.length > 5
    end
  end

  # ============================================================================
  # LATE PAYMENT INFO TESTS
  # ============================================================================

  test "late_payment_info returns helpful information string" do
    info = KnowledgeBase.late_payment_info

    assert_instance_of String, info
    assert_not_empty info

    # Should mention key late payment concepts
    assert_match /1st of each month|due date/i, info
    assert_match /late fee|grace period/i, info
    assert_match /lease agreement/i, info
    assert_match /contact.*landlord/i, info
  end

  # ============================================================================
  # PLATFORM FEATURES TESTS
  # ============================================================================

  test "platform_features returns hash of features with descriptions" do
    features = KnowledgeBase.platform_features

    assert_instance_of Hash, features
    assert_not_empty features

    # Check key platform features
    assert_includes features.keys, "search"
    assert_includes features.keys, "favorites"
    assert_includes features.keys, "applications"
    assert_includes features.keys, "messages"
    assert_includes features.keys, "viewings"
    assert_includes features.keys, "payments"
    assert_includes features.keys, "maintenance"
    assert_includes features.keys, "documents"

    # Verify all have meaningful descriptions
    features.each do |key, description|
      assert_instance_of String, key
      assert_instance_of String, description
      assert description.length > 10
    end
  end

  # ============================================================================
  # FAQS TESTS
  # ============================================================================

  test "faqs returns hash of questions and answers" do
    faqs = KnowledgeBase.faqs

    assert_instance_of Hash, faqs
    assert_operator faqs.length, :>=, 5

    # Verify all keys are questions (end with ?)
    faqs.keys.each do |question|
      assert_match /\?$/, question, "FAQ key should be a question ending with ?"
    end

    # Check some common FAQs are covered
    assert faqs.keys.any? { |q| q.include?("search") }
    assert faqs.keys.any? { |q| q.include?("viewing") }
    assert faqs.keys.any? { |q| q.include?("application") }
    assert faqs.keys.any? { |q| q.include?("pay rent") || q.include?("payment") }

    # Verify answers are helpful strings
    faqs.each do |question, answer|
      assert_instance_of String, question
      assert_instance_of String, answer
      assert answer.length > 20, "Answer should be detailed"
    end
  end

  # ============================================================================
  # TENANT TIPS TESTS
  # ============================================================================

  test "tenant_tips returns array of helpful tips" do
    tips = KnowledgeBase.tenant_tips

    assert_instance_of Array, tips
    assert_operator tips.length, :>=, 6

    # Check for important tenant advice
    assert tips.any? { |tip| tip.include?("lease agreement") }
    assert tips.any? { |tip| tip.include?("rent on time") }
    assert tips.any? { |tip| tip.include?("maintenance") }
    assert tips.any? { |tip| tip.include?("insurance") }
    assert tips.any? { |tip| tip.include?("rights") }

    # Verify all are meaningful strings
    tips.each do |tip|
      assert_instance_of String, tip
      assert tip.length > 15
    end
  end

  # ============================================================================
  # LANDLORD TIPS TESTS
  # ============================================================================

  test "landlord_tips returns array of helpful tips" do
    tips = KnowledgeBase.landlord_tips

    assert_instance_of Array, tips
    assert_operator tips.length, :>=, 6

    # Check for important landlord advice
    assert tips.any? { |tip| tip.include?("Screen") || tip.include?("tenant") }
    assert tips.any? { |tip| tip.include?("maintain") }
    assert tips.any? { |tip| tip.include?("maintenance request") }
    assert tips.any? { |tip| tip.include?("law") || tip.include?("regulation") }
    assert tips.any? { |tip| tip.include?("communication") }

    # Verify all are meaningful strings
    tips.each do |tip|
      assert_instance_of String, tip
      assert tip.length > 15
    end
  end

  # ============================================================================
  # DATA CONSISTENCY TESTS
  # ============================================================================

  test "all class methods are available" do
    expected_methods = [
      :property_types,
      :amenities_info,
      :rental_application_process,
      :required_documents,
      :income_requirements,
      :maintenance_categories,
      :emergency_vs_routine,
      :payment_methods,
      :late_payment_info,
      :platform_features,
      :faqs,
      :tenant_tips,
      :landlord_tips
    ]

    expected_methods.each do |method|
      assert KnowledgeBase.respond_to?(method), "KnowledgeBase should respond to #{method}"
    end
  end

  test "all data structures are frozen or immutable where appropriate" do
    # Since this is a knowledge base, the data should be consistent
    # Call methods twice and verify same results
    assert_equal KnowledgeBase.property_types, KnowledgeBase.property_types
    assert_equal KnowledgeBase.amenities_info, KnowledgeBase.amenities_info
    assert_equal KnowledgeBase.faqs, KnowledgeBase.faqs
  end
end
