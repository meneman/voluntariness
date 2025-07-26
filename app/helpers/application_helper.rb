module ApplicationHelper
  include Pagy::Frontend
  
  def current_theme
    return 'system' unless user_signed_in?
    current_user.theme_preference || 'system'
  end
  
  def dark_mode_class
    return '' unless user_signed_in?
    current_user.dark_mode? ? 'dark' : ''
  end
  
  def theme_icon_class(theme)
    case theme
    when 'light'
      'text-yellow-500'
    when 'dark'
      'text-blue-400'
    when 'system'
      'text-gray-600 dark:text-gray-400'
    else
      'text-gray-600 dark:text-gray-400'
    end
  end
  def render_turbo_stream_flash_messages
      turbo_stream.prepend "flash", partial: "layouts/flash"
  end

  def render_turbo_stream_action_flash_messages
      turbo_stream.prepend "flash", partial: "layouts/action_flash"
  end

  def form_error_notification(object)
      if object.errors.any?
          tag.div class: "error-message" do
          object.errors.full_messages.to_sentence.capitalize
          end
      end
  end


  def contrasting_color(hex_color)
      return nil unless hex_color

      hex_color = hex_color.delete("#")
      r = hex_color[0..1].hex
      g = hex_color[2..3].hex
      b = hex_color[4..5].hex

      # Calculate luminance (perceived brightness)
      luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

      # Return black for light backgrounds and white for dark backgrounds
      luminance > 0.5 ? "#000000" : "#FFFFFF"
  rescue StandardError
      nil
  end
end
