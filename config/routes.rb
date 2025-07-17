Rails.application.routes.draw do
  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resources :users, only: [ :index, :show, :edit, :update, :destroy ]
  end
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
  get "pages/gambling", as: :gambling

  # Gamble routes
  get "gamble", to: "gamble#index", as: :gamble
  post "gamble/select_participant", to: "gamble#select_participant", as: :gamble_select_participant
  post "gamble/spin", to: "gamble#spin", as: :gamble_spin
  post "gamble/result", to: "gamble#result", as: :gamble_result
  post "gamble/reset", to: "gamble#reset", as: :gamble_reset
  get "participants/cancel", to: "participants#cancel", as: :cancel_participant,  defaults: { format: :turbo_stream }
  get "/tasks/cancel", to: "tasks#cancel", as: :cancel_task,  defaults: { format: :turbo_stream }
  get "/tasks/cancel", to: "tasks#cancel", as: :cancel_tasks,  defaults: { format: :turbo_stream }

  # devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :tasks
  resources :participants
  resources :useable_items, only: [ :index, :show, :create, :destroy ]

  # patch :archive
  # patch :participants, :archive
  patch "/participants/archive/:id", to: "participants#archive", as: :archive_participant, defaults: { format: :turbo_stream }
  patch "/participants/unarchive/:id", to: "participants#unarchive", as: :unarchive_participant, defaults: { format: :turbo_stream }
  patch "/tasks/archive/:id", to: "tasks#archive", as: :archive_task, defaults: { format: :turbo_stream }
  patch "/tasks/unarchive/:id", to: "tasks#unarchive", as: :unarchive_task, defaults: { format: :turbo_stream }

  resources :actions do
    member do
      post :add_participant, defaults: { format: :turbo_stream }
    end
  end
  resources :bets
  # Style Guide
  get "style-guide", to: "style_guide#index", as: :style_guide

  post :action, to: "action#create", defaults: { format: :turbo_stream }
  # post :participant, to: "participants#archive", defaults: {format: :turbo_stream}

  get "settings", to: "pages#settings", as: :settings

  patch "/settings/toggle_streak_boni", to: "settings#toggle_streak_boni", as: :toggle_streak_boni
  patch "/settings/toggle_overdue_bonus", to: "settings#toggle_overdue_bonus", as: :toggle_overdue_bonus

  patch "/settings/update_streak_bonus_days_threshold", to: "settings#update_streak_bonus_days_threshold", as: :update_streak_bonus_days_threshold
  post "toggle_theme", to: "application#toggle_theme"
  
  # Pricing page
  get "pricing", to: "pages#pricing", as: :pricing
  # Landing page for non-authenticated users
  root "landing#index"

  # Home page for authenticated users
  get "home", to: "pages#home", as: :pages_home
end
