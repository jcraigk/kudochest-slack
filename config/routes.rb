require "sidekiq/web"
require "sidekiq-scheduler/web"
require "sidekiq_unique_jobs/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq", constraints: AdminConstraint.new

  get "healthz", to: "ops#healthz"

  # Web sessions
  root to: "sessions#new"
  delete :logout, to: "sessions#destroy", as: :logout

  # Private
  get :dashboard, to: "dashboard#show", as: :dashboard
  # get :wallboard, to: "wallboard#show", as: :wallboard

  namespace :hooks do
    namespace :slack do
      post :action, to: "actions#receiver"
      post :command, to: "commands#receiver"
      post :event, to: "events#receiver"
      post :options, to: "options#receiver"
    end
  end

  namespace :slack do
    get :install
    get :install_callback
    get :login
    get :login_callback
  end

  namespace :onboarding do
    patch :join_all_channels
    # patch :join_specific_channels
    patch :skip_join_channels
    # patch :confirm_emoji_added
    # patch :skip_emoji
  end

  resources :teams, only: %i[edit update] do
    collection do
      get :leaderboard_page
    end
    member do
      patch :reset_stats
      patch :uninstall
      patch :export_data
    end
  end
  get :app_settings, to: "teams#edit"

  resources :profiles, only: %i[show edit update] do
    collection do
      get :random_showcase
    end
  end
  get :preferences, to: "profiles#edit"

  resources :tips, only: %i[index destroy]
  resources :rewards, except: %i[show]
  resources :topics, except: %i[show]
  resources :bonuses, only: %i[index create]
  resources :claims, except: %i[new create]

  get  :shop,         to: "rewards#shop"
  get  :topic_list,   to: "topics#list"
  post :claim_reward, to: "rewards#claim"
  get  :my_claims,    to: "claims#my_claims"
  get  :unsubscribe,  to: "emails#unsubscribe"

  match "/404", to: "errors#not_found", via: :all
  match "/403", to: "errors#forbidden", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
