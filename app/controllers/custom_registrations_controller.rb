class CustomRegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [ :update ]

  protected

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username ])
  end
end
