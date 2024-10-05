Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]
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


  
  # Defines the root path route ("/") 
  root "pages#home"
end
