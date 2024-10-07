    class ApplicationController < ActionController::Base
        before_action :authenticate_user!, except: [:landing]
        before_action :set_theme

        include Pagy::Backend

        def set_theme
          if cookies[:theme].present?
            @theme = cookies[:theme]
          else
            @theme = 'LIGHT' # Default to LIGHT theme
            cookies[:theme] = @theme
          end
        end

        def toggle_theme
          new_theme = cookies[:theme] == 'LIGHT' ? 'DARK' : 'LIGHT'
          cookies[:theme] = new_theme
        end
      
        def after_sign_in_path_for(resource)
            root_path
        end
    end
