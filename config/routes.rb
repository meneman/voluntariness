Rails.application.routes.draw do
  get 'articles/index'
  get 'pages/statistics', as: :statistics

  # devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :tasks
  resources :participants do
    member do 
      patch :update_points
      
    end
  end
  # patch :archive_participant
  # patch :participants, :archive_participant
  post "/participants/archive_participant/:id", to: "participants#archive_participant", as: :archive_participant, defaults: {format: :turbo_stream} 

  resources :actions
  
  post :action, to: "action#create", defaults: {format: :turbo_stream}
  # post :participant, to: "participants#archive_participant", defaults: {format: :turbo_stream}

  post "task/cancel" ,as: :cancel_task,  defaults: {format: :turbo_stream}
  
  get "participant/cancel" ,as: :participant_cancel,  defaults: {format: :turbo_stream}
  # get "/blog_posts/new", to: "blog_posts#new", as: :new_blog_post
  # get "/blog_posts/:id", to: "blog_posts#show", as: :blog_post
  # delete "/blog_posts/:id", to: "blog_posts#destroy"
  # patch "/blog_posts/:id", to: "blog_posts#update"
  # get "/blog_posts/:id/edit", to: "blog_posts#edit", as: :edit_blog_post
  # post "/blog_posts", to: "blog_posts#create", as: :blog_posts
  

  
  # Defines the root path route ("/") 

  root "pages#home"
end
