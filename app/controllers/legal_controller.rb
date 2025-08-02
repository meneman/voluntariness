class LegalController < ApplicationController
  skip_before_action :authenticate_user!, only: [:terms, :privacy]
  skip_before_action :ensure_current_household, only: [:terms, :privacy]

  def terms
  end

  def privacy
  end
end