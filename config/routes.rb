Rails.application.routes.draw do
  # User Account API routes
  post '/signup', to: 'api/users#create'
  get '/users/:user_id', to: 'api/users#show'
  patch '/users/:user_id', to: 'api/users#update'
  post '/close', to: 'api/users#destroy'
  
  resources :posts
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "posts#index"
end
