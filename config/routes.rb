Rails.application.routes.draw do
  resources :partners do
    member do
      get :email
      get :picture
      post :picture_save
    end
  end

  resources :users do
    resource :password
    resource :profile
    resources :messages
    resources :followings, only: [:index, :show, :update], collection: { multiple: :put }
    resources :contacts, controller: :user_contacts, path: 'contacts', as: 'contacts', only: [:index] do
      collection do
        get 'following'
        get 'members'
        get 'not_invited'
        get 'invited'
        put 'multiple'
      end
    end

    collection do
      get 'endorsements'
      post 'order'
      get 'ads'
      get 'priorities'
      get 'signups'
      get 'legislators'
      post 'legislators_save'
    end

    member do
      put 'suspend'
      put 'unsuspend'
      get 'activities'
      get 'comments'
      get 'points'
      get 'discussions'
      get 'capital'
      put 'impersonate'
      get 'followers'
      get 'documents'
      get 'stratml'
      get 'ignorers'
      get 'following'
      get 'ignoring'
      post 'follow'
      post 'unfollow'
      put 'make_admin'
      post 'endorse'
      get 'reset_password'
      get 'resend_activation'
    end
  end

  
  resources :settings do
    collection do
      get :signups
      get :picture
      post :picture_save
      get :legislators
      post :legislators_save
      get :branch_change
      get :delete
    end
  end
  
  resources :priorities do
    member do
      put :flag_inappropriate
      put :bury
      put :compromised
      put :successful
      put :failed
      put :intheworks
      post :endorse
      get :endorsed
      get :opposed
      get :activities
      get :endorsers
      get :opposers
      get :discussions
      put :create_short_url
      post :tag
      put :tag_save
      get :points
      get :opposer_points
      get :endorser_points
      get :neutral_points
      get :everyone_points
      get :opposer_documents
      get :endorser_documents
      get :neutral_documents
      get :everyone_documents
      get :comments
      get :documents
    end
    
    collection do
      get :yours
      get :yours_finished
      get :yours_top
      get :yours_ads
      get :yours_lowest
      get :yours_created
      get :network
      get :consider
      get :obama
      get :not_obama
      get :obama_opposed
      get :finished
      get :ads
      get :top
      get :rising
      get :falling
      get :controversial
      get :random
      get :newest
      get :untagged
    end
    
    resources :changes do
      member do
        put :start
        put :stop
        put :approve
        put :flip
        get :activities
      end
      resources :votes
    end
    
    resources :points
    resources :documents
    resources :ads do
      collection do
        post :preview
      end
      member do
        post :skip
      end
    end
  end

  resources :activities do
  member do
    put :undelete
    get :unhide
  end
  resources :followings, controller: :following_discussions, as: "followings"
  resources :comments, only: [] do
    collection do
      get :more
    end
    member do
      get :unhide
      get :flag
      post :not_abusive
      post :abusive
    end
  end
end

  resources :points do
    member do
      get :activity
      get :discussions
      post :quality
      post :unquality
      get :unhide
    end
    collection do
      get :newest
      get :revised
      get :your_priorities
    end
    resources :revisions do
      member do
        get :clean
      end
    end
  end

  resources :documents do
    member do
      get :activity
      get :discussions
      post :quality
      post :unquality
      get :unhide
    end
    collection do
      get :newest
      get :revised
      get :your_priorities
    end
    resources :revisions, controller: :document_revisions, as: "revisions" do
      member do
        get :clean
      end
    end
  end

  resources :legislators do
    member do
      get :priorities
    end
    resources :constituents do
      collection do
        get :priorities
      end
    end
  end

  resources :blurbs do
    collection do
      put :preview
    end
  end

  resources :email_templates do
    collection do
      put :preview
    end
  end

  resources :color_schemes do
    collection do
      put :preview
    end
  end

  resources :governments do
    member do
      get :apis
    end
  end

  resources :widgets do
    collection do
      get :priorities
      get :discussions
      get :points
      get :preview_iframe
      post :preview
    end
  end

  resources :bulletins do
    member do
      post :add_inline
    end
  end

  resources :branches do
    member do
      post :default
    end
    resources :priorities, controller: :branch_priorities, as: "priorities", only: [] do
      collection do
        get :top
        get :rising
        get :falling
        get :controversial
        get :random
        get :newest
        get :finished
      end
    end
    resources :users, controller: :branch_users, as: "users", only: [] do
      collection do
        get :talkative
        get :twitterers
        get :newest
        get :ambassadors
      end
    end
  end

  resources :searches, only: [] do
    collection do
      get :points
      get :documents
    end
  end

  resources :signups, :endorsements, :passwords, :unsubscribes, :notifications, :pages, :about, :tags

  resource :session

  resources :delayed_jobs do
    member do
      get :top
      get :clear
    end
  end
  
  
  root to: "priorities#index"

  # restful_authentication routes
  get "/activate/:activation_code", to: "users#activate", as: "activate", activation_code: nil
  get "/signup", to: "users#new", as: "signup_page"
  get "/login", to: "sessions#new", as: "login"
  delete "/logout", to: "sessions#destroy", as: "logout"
  get "/unsubscribe", to: "unsubscribes#new", as: "unsubscribe_page"
  get '/network', to: 'network#index'

  # non restful routes
  get "/yours", to: "priorities#yours", as: "yours"
  get "/hot", to: "priorities#hot", as: "hot"
  get "/cold", to: "priorities#cold", as: "cold"
  get "/new", to: "priorities#new", as: "new"
  get "/controversial", to: "priorities#controversial", as: "controversial"

  get "/vote/:action/:code", to: "vote#:action", as: "vote"
  get "/splash", to: "splash#index", as: "splash"
  resources :issues, param: :slug

  # Install the default routes as the lowest priority.
  resources :pictures, param: :short_name do
    member do
      get ":action/(:id)", action: /\w+/
    end
  end
end