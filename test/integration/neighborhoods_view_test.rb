require "test_helper"

class NeighborhoodsViewTest < ActionDispatch::IntegrationTest
  test "neighborhoods page renders successfully" do
    get neighborhoods_path
    assert_response :success
    # The h1 contains "Explore" and "Neighborhoods" in separate spans
    assert_select "h1" do |elements|
      h1_text = elements.first.text.gsub(/\s+/, " ").strip
      assert_match(/Explore.*Neighborhoods/i, h1_text)
    end
  end

  test "neighborhoods page shows featured communities section" do
    get neighborhoods_path
    assert_response :success
    # The page has static hardcoded neighborhood content
    assert_select "h2" do |elements|
      h2_texts = elements.map { |el| el.text.gsub(/\s+/, " ").strip }
      assert h2_texts.any? { |text| text.include?("Featured") || text.include?("Communities") },
             "Expected to find a Featured Communities heading"
    end
  end

  test "neighborhoods page shows neighborhood features section" do
    get neighborhoods_path
    assert_response :success
    # Check for the key features section
    assert_select "h3", /Transportation|Schools|Shopping|Recreation|Safety|Healthcare/
  end
end
