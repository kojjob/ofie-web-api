require "test_helper"

class ToolsViewsTest < ActionDispatch::IntegrationTest
  test "calculators page renders successfully" do
    get calculators_path
    assert_response :success
    assert_select "h1", /Rental Calculators/
    # The calculators page uses buttons with onclick handlers, not forms
    # Check for calculator card containers (divs with shadow-lg class in grid)
    assert_select "button[onclick^='openCalculator']", minimum: 6
  end

  test "landlord tools page renders successfully" do
    get landlord_tools_path
    assert_response :success
    assert_select "h1", /Landlord Tools/
  end
end
