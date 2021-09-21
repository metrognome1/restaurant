Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :v1 do
    post '/search', to: 'api#search'
    get '/photo_lookup', to: 'api#photo_lookup'
  end
end
