Rails.application.routes.draw do
  resources :households do
    member do
      patch :switch_household
    end
    collection do
      get :join
      post :join
    end
  end
  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resources :users, only: [ :index, :show, :edit, :update, :destroy ]
  end
  # Firebase authentication routes (Devise removed)
  get "password/edit", to: "passwords#edit", as: "edit_password"
  patch "password/update", to: "passwords#update", as: "update_password"

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
  get "pages/chatgpt_data", as: :chatgpt_data

  # Gamble routes
  get "gamble", to: "gamble#index", as: :gamble
  post "gamble/select_participant", to: "gamble#select_participant", as: :gamble_select_participant
  post "gamble/spin", to: "gamble#spin", as: :gamble_spin
  post "gamble/result", to: "gamble#result", as: :gamble_result
  post "gamble/reset", to: "gamble#reset", as: :gamble_reset
  get "participants/cancel", to: "participants#cancel", as: :cancel_participant,  defaults: { format: :turbo_stream }
  get "/tasks/cancel", to: "tasks#cancel", as: :cancel_task,  defaults: { format: :turbo_stream }
  get "/tasks/cancel", to: "tasks#cancel", as: :cancel_tasks,  defaults: { format: :turbo_stream }

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
  
  # Theme API endpoint
  patch '/api/theme', to: 'users#update_theme'
  
  # Pricing page
  get "pricing", to: "pages#pricing", as: :pricing
  # Landing page for non-authenticated users
  root "landing#index"

  # Home page for authenticated users
  get "home", to: "pages#home", as: :pages_home

  # Firebase authentication routes
  get "sign_in", to: "auth#sign_in"
  get "sign_up", to: "auth#sign_up"
  post "auth/verify_token", to: "auth#verify_token"
  delete "sign_out", to: "auth#sign_out"
  delete "auth/delete_account", to: "auth#delete_account"

  # Legal pages
  get "impressum", to: "impressum#index", as: :impressum
  get "terms", to: "legal#terms", as: :terms
  get "privacy", to: "legal#privacy", as: :privacy
  
  # SEO routes
  get "sitemap.xml", to: "sitemaps#index", format: :xml
  get "robots.txt", to: "sitemaps#robots", format: :text

  # Firebase testing routes (remove these in production)
  get "firebase/test", to: "firebase_test#test_config"
  get "firebase/test_page", to: "firebase_test#test_page"
  post "firebase/test_token", to: "firebase_test#test_token"
end
