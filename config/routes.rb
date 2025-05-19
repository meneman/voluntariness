Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "password/edit", to: "passwords#edit", as: "edit_password"
  patch "password/update", to: "passwords#update", as: "update_password"
  # Enable just the routes needed for password change
  # as :user do
  #   get "users/edit", to: "devise/registrations#edit", as: "edit_user_registration"
  #   put "users", to: "devise/registrations#update", as: "user_registration"
  # end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  get "pages/statistics", as: :statistics
  get "participants/cancel", to: "participants#cancel", as: :cancel_participant,  defaults: { format: :turbo_stream }
  get "/tasks/cancel", to: "tasks#cancel", as: :cancel_task,  defaults: { format: :turbo_stream }

  # devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :tasks
  resources :participants do
    member do
      patch :update_points
    end
  end

  # patch :archive
  # patch :participants, :archive
  post "/participants/archive/:id", to: "participants#archive", as: :archive_participant, defaults: { format: :turbo_stream }
  post "/tasks/archive/:id", to: "tasks#archive", as: :archive_task, defaults: { format: :turbo_stream }

  resources :actions

  post :action, to: "action#create", defaults: { format: :turbo_stream }
  # post :participant, to: "participants#archive", defaults: {format: :turbo_stream}

  get "settings", to: "pages#settings", as: :settings

  post "/settings/toggle_streak_boni_path", to: "settings#toggle_streak_boni", as: :toggle_streak_boni
  post "/settings/toggle_overdue_bonus", to: "settings#toggle_overdue_bonus", as: :toggle_overdue_bonus

  post "/settings/update_streak_bonus_days_trashhold", to: "settings#update_streak_bonus_days_trashhold", as: :update_streak_bonus_days_trashhold
  post "toggle_theme", to: "application#toggle_theme"
  # Defines the root path route ("/")
  root "pages#home"
end
