require "test_helper"

class PropertyFieldsTest < ActiveSupport::TestCase
  def setup
    @controller = BatchPropertiesController.new
  end

  test "CSV headers match actual Property model columns" do
    headers = @controller.send(:get_property_csv_headers)

    # Get actual Property columns (excluding system fields)
    actual_columns = Property.column_names.reject do |attr|
      %w[id user_id created_at updated_at].include?(attr)
    end

    # Check that all actual columns are included in headers
    actual_columns.each do |column|
      assert_includes headers, column, "CSV headers should include Property column: #{column}"
    end

    # Check that we don't have any non-existent columns
    headers.each do |header|
      next if header == "photo_filenames" # This is a custom field

      assert_includes Property.column_names, header, "Header '#{header}' should exist as a Property column"
    end
  end

  test "boolean fields in sanitize_property_params match actual Property columns" do
    # Get the boolean fields from the controller
    property_data = { parking_available: "true", laundry: "false", gym: "true" }
    sanitized = @controller.send(:sanitize_property_params, property_data)

    # These should work without errors
    assert_nothing_raised do
      property = Property.new(sanitized)
    end
  end

  test "Property model has expected boolean columns" do
    expected_boolean_columns = %w[
      parking_available pets_allowed furnished utilities_included
      laundry air_conditioning heating internet_included gym pool balcony
    ]

    expected_boolean_columns.each do |column|
      assert Property.column_names.include?(column), "Property should have column: #{column}"
    end
  end
end
