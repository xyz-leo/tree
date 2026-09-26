Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Sign in at /sessions/new. There is a single user, created by db/seeds.rb.
  resource :session, path: "sessions", only: %i[ new create destroy ]

  # Everything editable on the page. Requires sign in.
  namespace :admin do
    root "dashboard#show"
    resource :profile, only: %i[ edit update ]
    resources :link_groups, except: %i[ index show ] do
      resources :links, only: %i[ new create ]
    end
    resources :links, only: %i[ edit update destroy ]
  end

  # Portuguese is the default; English lives under /en.
  root "links#index", lang: "pt"
  get "en" => "links#index", lang: "en", as: :en
end
