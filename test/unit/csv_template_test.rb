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

    # Verify example values are placeholders, not hard-coded data
    example_row = lines[1]
    assert_includes example_row, "[Property Title]"
    assert_includes example_row, "[Property Description]"
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

    boolean_fields = [
      "parking_available", "pets_allowed", "furnished",
      "utilities_included", "laundry_available"
    ]

    boolean_fields.each do |field|
      assert_includes csv_content, field, "CSV template should include #{field}"
    end
  end

  test "CSV template includes placeholder example data" do
    csv_content = @controller.send(:generate_manual_csv_template)

    # Check for placeholder values instead of hard-coded data
    assert_includes csv_content, "[Property Title]"
    assert_includes csv_content, "[Street Address]"
    assert_includes csv_content, "[City Name]"
    assert_includes csv_content, "[Monthly Rent Amount]"
    assert_includes csv_content, "[apartment/house/condo/etc]"
    assert_includes csv_content, "[available/rented/maintenance]"
    assert_includes csv_content, "[true/false]"
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

  test "example values are generated as placeholders" do
    headers = [ "title", "price", "parking_available", "custom_field" ]
    example_values = @controller.send(:generate_example_values, headers)

    assert_equal headers.length, example_values.length
    assert_equal "[Property Title]", example_values[0]
    assert_equal "[Monthly Rent Amount]", example_values[1]
    assert_equal "[true/false]", example_values[2]
    assert_equal "[Custom field]", example_values[3]
  end
end
