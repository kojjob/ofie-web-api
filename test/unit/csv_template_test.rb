require "test_helper"

class CsvTemplateTest < ActiveSupport::TestCase
  def setup
    @controller = BatchPropertiesController.new
  end

  test "manual CSV template generation works" do
    csv_content = @controller.send(:generate_manual_csv_template)
    
    assert_not_nil csv_content
    assert_includes csv_content, "title,description,address,city,price"
    assert_includes csv_content, "Beautiful 2BR Apartment Downtown"
    assert_includes csv_content, "property_type"
    assert_includes csv_content, "photo_filenames"
    
    # Verify it has proper CSV structure
    lines = csv_content.split("\n")
    assert_equal 2, lines.length # Header + example row
    
    # Verify header count
    headers = lines[0].split(",")
    assert_equal 23, headers.length # Should have 23 property fields
  end

  test "CSV template includes all required property fields" do
    csv_content = @controller.send(:generate_manual_csv_template)
    
    required_fields = [
      'title', 'description', 'address', 'city', 'price', 
      'bedrooms', 'bathrooms', 'property_type'
    ]
    
    required_fields.each do |field|
      assert_includes csv_content, field, "CSV template should include #{field}"
    end
  end

  test "CSV template includes boolean fields" do
    csv_content = @controller.send(:generate_manual_csv_template)
    
    boolean_fields = [
      'parking_available', 'pets_allowed', 'furnished', 
      'utilities_included', 'laundry_available'
    ]
    
    boolean_fields.each do |field|
      assert_includes csv_content, field, "CSV template should include #{field}"
    end
  end

  test "CSV template includes example data" do
    csv_content = @controller.send(:generate_manual_csv_template)
    
    # Check for example values
    assert_includes csv_content, "Beautiful 2BR Apartment Downtown"
    assert_includes csv_content, "123 Main Street"
    assert_includes csv_content, "New York"
    assert_includes csv_content, "2500"
    assert_includes csv_content, "apartment"
    assert_includes csv_content, "available"
  end
end
