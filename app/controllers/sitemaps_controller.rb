class SitemapsController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    respond_to do |format|
      format.xml { render layout: false }
    end
  end

  def robots
    respond_to do |format|
      format.text { render layout: false }
    end
  end
end