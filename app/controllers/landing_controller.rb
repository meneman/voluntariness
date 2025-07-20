class LandingController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
  layout "landing"

  def index
    # Landing page for non-authenticated users
    if user_signed_in?
      redirect_to pages_home_path
    end
  end
end
