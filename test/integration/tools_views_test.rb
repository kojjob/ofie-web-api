require "test_helper"

class ToolsViewsTest < ActionDispatch::IntegrationTest
  test "calculators page renders successfully" do
    get calculators_path
    assert_response :success
    assert_select "h1", "Rental Property Calculators"
    assert_select "form", minimum: 6 # Should have at least 6 calculator forms
  end

  test "landlord tools page renders successfully" do
    get landlord_tools_path
    assert_response :success
    assert_select "h1", "Landlord Tools & Resources"
  end
end
