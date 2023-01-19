Rails.application.routes.draw do

  resources :channels do
    resources :messages
  end
  resources :users
  resources :sessions
  delete '/logout', to: 'sessions#destroy'
  root to: 'channels#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
