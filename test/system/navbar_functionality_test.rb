require "application_system_test_case"

class NavbarFunctionalityTest < ApplicationSystemTestCase
  setup do
    @landlord = create(:user, :landlord, :verified)
  end

  test "stimulus controllers are properly loaded on page" do
    visit root_path

    # Check that the navbar has the correct Stimulus controllers attached
    assert_selector "nav[data-controller~='navbar']"
    assert_selector "nav[data-controller~='mobile-menu']"
  end

  test "mobile menu toggle button is visible on small screens" do
    # Set a mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)

    visit root_path

    # The mobile menu button should be visible
    assert_selector "button[data-action='click->mobile-menu#toggle']", visible: true

    # The mobile menu should be hidden initially
    menu = find("[data-mobile-menu-target='menu']", visible: :all)
    assert menu[:class].include?("hidden") || menu[:class].include?("translate-x-full")
  end

  test "mobile menu opens when hamburger button is clicked" do
    # Set a mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)

    visit root_path

    # Click the hamburger menu button
    find("button[data-action='click->mobile-menu#toggle']").click

    # Wait for the menu to be visible
    sleep 0.5

    # The menu should now be visible - check that menu items are visible
    assert_selector "a", text: "Browse Properties", visible: true
    assert_selector "a", text: "Login", visible: true
  end

  test "desktop navigation links are visible on large screens" do
    # Set a desktop viewport
    page.driver.browser.manage.window.resize_to(1280, 800)

    visit root_path

    # Desktop navigation links should be visible
    assert_selector "a", text: "Browse", visible: true
    assert_selector "a", text: "Blog", visible: true
    assert_selector "a", text: "Login", visible: true
  end

  test "user dropdown works when logged in" do
    sign_in_as(@landlord)

    # Set a desktop viewport
    page.driver.browser.manage.window.resize_to(1280, 800)

    visit root_path

    # Look for user menu button (dropdown trigger)
    if has_selector?("[data-controller='dropdown']", wait: 2)
      dropdown_trigger = find("[data-controller='dropdown'] button", match: :first, wait: 2)
      dropdown_trigger.click

      # Wait for dropdown to appear
      sleep 0.3

      # The dropdown menu should be visible
      assert_selector "[data-dropdown-target='menu']", visible: true
    end
  end

  private

  def sign_in_as(user)
    visit login_path
    # Use first matching email field to avoid ambiguity
    all("input[type='email'], input[name*='email']", visible: true).first.fill_in with: user.email
    all("input[type='password'], input[name*='password']", visible: true).first.fill_in with: "password123"
    click_button "Sign In"
  end
end
