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
    
end
