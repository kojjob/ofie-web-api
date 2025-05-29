module FlashHelper
  # Enhanced flash message helper methods

  def flash_message(type, message, options = {})
    flash[type] = {
      message: message,
      options: options
    }
  end

  def flash_success(message, options = {})
    flash[:success] = message
  end

  def flash_error(message, options = {})
    flash[:error] = message
  end

  def flash_warning(message, options = {})
    flash[:warning] = message
  end

  def flash_info(message, options = {})
    flash[:info] = message
  end

  def flash_notice(message, options = {})
    flash[:notice] = message
  end

  def flash_alert(message, options = {})
    flash[:alert] = message
  end

  # Method to render flash messages with custom styling
  def render_flash_message(type, message, options = {})
    default_options = {
      dismissible: true,
      duration: 5000,
      animation: "slide",
      position: "inline"
    }

    merged_options = default_options.merge(options)

    content_tag :div,
                class: "flash-message-wrapper",
                data: {
                  controller: "flash",
                  flash_type_value: type,
                  flash_duration_value: merged_options[:duration],
                  flash_position_value: merged_options[:position],
                  flash_animation_value: merged_options[:animation],
                  flash_dismissible_value: merged_options[:dismissible],
                  action: "mouseenter->flash#pauseAutoHide mouseleave->flash#resumeAutoHide"
                } do
      content_tag :div, message, class: "flash-content"
    end
  end

  # Method to get flash icon based on type
  def flash_icon(type)
    icons = {
      success: '<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      error: '<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      warning: '<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>',
      info: '<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      notice: '<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5-5-5h5v-12"></path></svg>',
      alert: '<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
    }

    icons[type.to_sym] || icons[:info]
  end

  # Method to get flash color classes based on type
  def flash_color_classes(type)
    colors = {
      success: "bg-gradient-to-r from-green-500 to-green-600 text-white border-l-4 border-green-700",
      error: "bg-gradient-to-r from-red-500 to-red-600 text-white border-l-4 border-red-700",
      warning: "bg-gradient-to-r from-yellow-500 to-yellow-600 text-white border-l-4 border-yellow-700",
      info: "bg-gradient-to-r from-blue-500 to-blue-600 text-white border-l-4 border-blue-700",
      notice: "bg-gradient-to-r from-indigo-500 to-indigo-600 text-white border-l-4 border-indigo-700",
      alert: "bg-gradient-to-r from-red-500 to-red-600 text-white border-l-4 border-red-700"
    }

    colors[type.to_sym] || colors[:info]
  end

  # Method to check if there are any flash messages
  def has_flash_messages?
    flash.any? { |type, message| message.present? }
  end

  # Method to get flash message count
  def flash_message_count
    flash.count { |type, message| message.present? }
  end

  # Method to clear all flash messages
  def clear_flash_messages
    flash.clear
  end
end
