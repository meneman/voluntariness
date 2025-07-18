class RegistrationsController < Devise::RegistrationsController
  # Override the create action to prevent new user registration
  def create
    redirect_to new_user_registration_path, alert: "Registration is currently by invitation only."
  end
end