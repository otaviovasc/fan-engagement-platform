Rails.application.routes.draw do
  root 'home#lp'
  get '/signup', to: 'home#signup'
  get '/privacy', to: 'home#privacy'
  get '/terms', to: 'home#terms'

  # The OmniAuth callback route
  get '/auth/:provider/callback', to: 'sessions#omniauth_callback'

  # Login and Logout routes
  delete '/logout', to: 'sessions#destroy'

  # User routes
  get '/profile', to: 'profiles#show'
  get '/artist/:id', to: 'artists#show', as: 'artist'

  # Handle OAuth failures
  get '/auth/failure', to: 'sessions#failure'

  resources :user_waitlists, only: [:new, :create]
end
