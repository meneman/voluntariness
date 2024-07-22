class ApplicationController < ActionController::Base
    before_action :authenticate_user!, except: [:landing]
    include Pagy::Backend
end
