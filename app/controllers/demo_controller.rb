class DemoController < ApplicationController
  skip_before_action :authenticate_request, only: [ :flash_demo ]

  def flash_demo
    # This action will be used to demonstrate different flash message types
  end

  def test_success
    flash[:success] = "🎉 Success! Your action was completed successfully."
    redirect_to demo_flash_demo_path
  end

  def test_error
    flash[:error] = "❌ Error! Something went wrong. Please try again."
    redirect_to demo_flash_demo_path
  end

  def test_warning
    flash[:warning] = "⚠️ Warning! Please review your input before proceeding."
    redirect_to demo_flash_demo_path
  end

  def test_info
    flash[:info] = "ℹ️ Info: Here's some helpful information for you."
    redirect_to demo_flash_demo_path
  end

  def test_notice
    flash[:notice] = "📢 Notice: Your settings have been updated."
    redirect_to demo_flash_demo_path
  end

  def test_alert
    flash[:alert] = "🚨 Alert! Immediate attention required."
    redirect_to demo_flash_demo_path
  end

  def test_multiple
    flash[:success] = "✅ Operation completed successfully!"
    flash[:info] = "📝 Don't forget to save your changes."
    flash[:warning] = "⚠️ Some features may be limited."
    redirect_to demo_flash_demo_path
  end
end
