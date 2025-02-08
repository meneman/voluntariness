module ApplicationHelper
  include Pagy::Frontend
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
      hex_color = hex_color.delete("#")
      r = hex_color[0..1].hex
      g = hex_color[2..3].hex
      b = hex_color[4..5].hex

      # Calculate luminance (perceived brightness)
      luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

      # Return black for light backgrounds and white for dark backgrounds
      luminance > 0.5 ? "#000000" : "#FFFFFF"
      rescue nil
  end
end
