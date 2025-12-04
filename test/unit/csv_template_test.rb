require "test_helper"

class CsvTemplateTest < ActiveSupport::TestCase
  def setup
    @controller = BatchPropertiesController.new
  end

  test "manual CSV template generation works" do
    csv_content = @controller.send(:generate_manual_csv_template)

    assert_not_nil csv_content
    assert_includes csv_content, "title"
    assert_includes csv_content, "description"
    assert_includes csv_content, "address"
    assert_includes csv_content, "city"
    assert_includes csv_content, "price"
    assert_includes csv_content, "property_type"
    assert_includes csv_content, "photo_filenames"

    # Verify it has proper CSV structure
    lines = csv_content.split("\n")
    assert_equal 2, lines.length # Header + example row

    # Verify headers are present
    headers = lines[0].split(",")
    assert headers.length > 10, "Should have multiple property fields"

    # Verify example values contain realistic data (not placeholders)
    example_row = lines[1]
    assert_includes example_row, "Modern Downtown Apartment"
    assert_includes example_row, "San Francisco"
  end

  test "CSV template includes all required property fields" do
    csv_content = @controller.send(:generate_manual_csv_template)

    required_fields = [
      "title", "description", "address", "city", "price",
      "bedrooms", "bathrooms", "property_type"
    ]

    required_fields.each do |field|
      assert_includes csv_content, field, "CSV template should include #{field}"
    end
  end

  test "CSV template includes boolean fields" do
    csv_content = @controller.send(:generate_manual_csv_template)

    # Use actual Property model boolean field names (not _available suffixes)
    boolean_fields = [
      "parking_available", "pets_allowed", "furnished",
      "utilities_included", "laundry"
    ]

    boolean_fields.each do |field|
      assert_includes csv_content, field, "CSV template should include #{field}"
    end
  end

  test "CSV template includes realistic example data" do
    csv_content = @controller.send(:generate_manual_csv_template)

    # Check for realistic example values (matching generate_example_values implementation)
    assert_includes csv_content, "Modern Downtown Apartment"
    assert_includes csv_content, "123 Main Street"
    assert_includes csv_content, "San Francisco"
    assert_includes csv_content, "2800"
    assert_includes csv_content, "apartment"
  end

  test "headers are generated dynamically from Property model" do
    headers = @controller.send(:get_property_csv_headers)

    assert_not_nil headers
    assert headers.is_a?(Array)
    assert headers.length > 5, "Should have multiple property fields"

    # Should include basic property fields
    assert_includes headers, "title"
    assert_includes headers, "description"
    assert_includes headers, "price"

    # Should include custom fields
    assert_includes headers, "photo_filenames"

    # Should not include system fields
    assert_not_includes headers, "id"
    assert_not_includes headers, "created_at"
    assert_not_includes headers, "updated_at"
  end

  test "example values are generated for each header" do
    headers = [ "title", "price", "parking_available", "custom_field" ]
    example_values = @controller.send(:generate_example_values, headers)

    assert_equal headers.length, example_values.length

    # Check that known fields get realistic values
    assert_equal "Modern Downtown Apartment", example_values[0]  # title
    assert_equal "2800", example_values[1]  # price
    assert_equal "true", example_values[2]  # parking_available (boolean)
    assert_equal "", example_values[3]  # custom_field (unknown field gets empty string)
  end

  test "boolean fields get true as example value" do
    boolean_headers = [ "parking_available", "pets_allowed", "furnished", "laundry" ]
    example_values = @controller.send(:generate_example_values, boolean_headers)

    example_values.each_with_index do |value, index|
      assert_equal "true", value, "Boolean field #{boolean_headers[index]} should have 'true' as example value"
    end
  end
end
