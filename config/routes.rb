Rails.application.routes.draw do
  resource  :session
  resources :passwords, param: :token

  # Authentication / signup
  get    "signup", to: "users#new",        as: :signup
  get    "login",  to: "sessions#new",     as: :login
  delete "logout", to: "sessions#destroy", as: :logout

  resources :priorities do
    member do
      post :endorse
      post :oppose
      post :unendorse
      get  :points
      get  :documents
      get  :activities
      get  :endorsers
      get  :opposers
    end
    collection do
      get :top
      get :rising
      get :falling
      get :controversial
      get :newest
      get :untagged
      get :finished
      get :random
      get :yours
    end
    resources :points, only: [:index, :new, :create, :show, :edit, :update, :destroy]
    resources :documents, only: [:index, :new, :create, :show, :edit, :update, :destroy]
    resources :changes, only: [:index, :new, :create, :show] do
      member do
        put :approve
        put :decline
      end
      resources :votes, only: [:create]
    end
  end

  # Endorsement reordering (the user's personal ranked list)
  resources :endorsements, only: [:index] do
    collection { post :reorder }
  end

  resources :points, only: [:index, :show] do
    member do
      post :quality
      post :unquality
    end
  end
  resources :documents, only: [:index, :show]

  resources :activities, only: [:index, :show] do
    resources :comments, only: [:create, :destroy]
  end
  get "feed", to: "activities#index", as: :feed

  resources :tags, only: [:index, :show], param: :slug
  resources :branches do
    member do
      get :priorities
      get :users
    end
  end

  resources :users, only: [:index, :show, :create] do
    member do
      get  :priorities
      get  :points
      get  :activities
      post :follow
      post :unfollow
    end
  end
  resource :settings, only: [:show, :edit, :update]

  resources :messages, only: [:index, :new, :create, :show, :destroy] do
    collection { get :sent }
  end
  resources :notifications, only: [:index] do
    collection { post :read_all }
  end

  resources :pages, only: [:show], param: :short_name

  namespace :admin do
    root to: "dashboard#index"
    resources :priorities, only: [:index, :destroy]
    resources :users, only: [:index] do
      member do
        post :make_admin
        post :suspend
      end
    end
    resources :pages
    resources :blurbs
    resource  :government, only: [:edit, :update]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "priorities#index"
end
