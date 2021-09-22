Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :v1 do
    post '/search', to: 'api#search'
    get '/photo_lookup', to: 'api#photo_lookup'
  end
end
