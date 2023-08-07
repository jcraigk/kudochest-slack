require 'sidekiq/web'
require 'sidekiq-scheduler/web'
require 'sidekiq_unique_jobs/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq', constraints: AdminConstraint.new

  get 'healthz', to: 'ops#healthz'

  root to: 'public#landing'

  # Public
  get :cookies,  to: 'public#cookie_policy',  as: :cookie_policy
  get :features, to: 'public#features',       as: :features
  get :help,     to: 'public#help',           as: :help
  get :pricing,  to: 'public#pricing',        as: :pricing
  get :privacy,  to: 'public#privacy_policy', as: :privacy_policy
  get :support,  to: 'inquiries#new',         as: :support
  get :terms,    to: 'public#terms',          as: :terms

  # Private
  get :dashboard, to: 'dashboard#show', as: :dashboard
  get :wallboard, to: 'wallboard#show', as: :wallboard

  namespace :hooks do
    namespace :slack do
      post :action, to: 'actions#receiver'
      post :command, to: 'commands#receiver'
      post :event, to: 'events#receiver'
      post :options, to: 'options#receiver'
    end
  end

  namespace :oauth do
    get :add_to_slack, to: 'slack#add_to_slack'
    get :slack_integration, to: 'slack#integration'

    get 'callback/:provider', to: 'sorcery#callback'
    get ':provider', to: 'sorcery#oauth', as: :at_provider
  end

  resources :users, only: [] do
    member do
      get :edit_preferences
      patch :update_preferences
      patch :update_email # TODO: Remove this and sync from Slack instead?
    end
  end
  get 'user-settings', to: 'users#edit_preferences', as: :user_settings
  resources :user_sessions, only: %i[new create destroy]
  get 'login', to: 'user_sessions#new', as: :login
  delete 'logout', to: 'user_sessions#destroy', as: :logout

  namespace :onboarding do
    patch 'join_all_channels'
    patch 'join_specific_channels'
    patch 'skip_join_channels'
    patch 'confirm_emoji_added'
    patch 'skip_emoji'
  end

  resources :teams, only: %i[edit update new] do
    collection do
      get 'leaderboard_page'
    end
    member do
      patch 'reset_stats'
      patch 'export_data'
    end
  end
  get 'app-settings', to: 'teams#edit', as: :app_settings

  resources :profiles, only: %i[show edit update] do
    collection do
      get 'random_showcase'
    end
  end

  resources :inquiries, only: %i[new create]
  resources :tips, only: %i[index destroy]
  resources :rewards, except: %i[show]
  resources :topics, except: %i[show]
  resources :bonuses, only: %i[index create]
  resources :claims, except: %i[new create]

  get  'shop',         to: 'rewards#shop',       as: :shop
  get  'topic-list',   to: 'topics#list',        as: :topic_list
  post 'claim',        to: 'rewards#claim',      as: :claim_reward
  get  'my-claims',    to: 'claims#my_claims',   as: :my_claims
  get  'unsubscribe',  to: 'emails#unsubscribe', as: :unsubscribe

  match '/404', to: 'errors#not_found', via: :all
  match '/403', to: 'errors#forbidden', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
