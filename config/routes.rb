Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  post '/save_companies', to: 'companies#save_companies'
  post '/delete_companies', to: 'companies#delete_companies'
  get '/favorite_companies', to: 'companies#favorite_companies'

  # Defines the root path route ("/")
  root "companies#index"
end
