Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  get 'pages/statistics', as: :statistics
  get "participants/cancel", to: "participants#cancel" ,as: :cancel_participant,  defaults: {format: :turbo_stream}
  get "/tasks/cancel", to: "tasks#cancel", as: :cancel_task,  defaults: {format: :turbo_stream}
  
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
  post "/participants/archive/:id", to: "participants#archive", as: :archive_participant, defaults: {format: :turbo_stream} 
  post "/tasks/archive/:id", to: "tasks#archive", as: :archive_task, defaults: {format: :turbo_stream} 
  
  resources :actions
  
  post :action, to: "action#create", defaults: {format: :turbo_stream}
  # post :participant, to: "participants#archive", defaults: {format: :turbo_stream}


  post 'toggle_theme', to: 'application#toggle_theme'  
  # Defines the root path route ("/") 
  root "pages#home"
end
