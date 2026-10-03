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
    resources :followings, only: [:index, :new, :edit, :show, :update] do
      collection do
        put :multiple
      end
    end
    resources :contacts, controller: :user_contacts, path: 'contacts', as: 'contacts', only: [:index, :new, :create] do
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
      get 'ads'
      get 'priorities'
      get 'signups'
      get 'legislators'
      post 'legislators_save'
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
  resources :comments do
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

  # Flat versions of nested resources — the original app resolved these
  # through Rails 2's default routes (e.g. /comments/:id).
  resources :comments
  resources :changes
  resources :ads
  resources :messages
  resources :followings

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
    resources :users, controller: :branch_users, as: "users" do
      collection do
        get :talkative
        get :twitterers
        get :newest
        get :ambassadors
      end
    end
  end

  resources :searches do
    collection do
      get :points
      get :documents
    end
  end

  resources :signups, as: "signup_records"
  resources :endorsements, :passwords, :unsubscribes, :notifications, :pages, :about, :tags

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
  get "/signup", to: "users#new", as: "signup"
  get "/login", to: "sessions#new", as: "login"
  post "/auth/mojoauth", to: "mojo_auth_sessions#create", as: "mojoauth_session"
  delete "/logout", to: "sessions#destroy", as: "logout"
  # Legacy links used plain GET for logout (Rails 2 map.logout).
  get "/logout", to: "sessions#destroy"
  get "/unsubscribe", to: "unsubscribes#new", as: "unsubscribe_page"
  get '/network', to: 'network#index'
  scope '/network', controller: 'network' do
    get :talkative
    get :ambassadors
    get :twitterers
    get :unverified
    get :warnings
    get :suspended
    get :probation
    get :deleted
    get :newest
    get :find
    get :search
    get :partners
  end

  # Legacy non-RESTful controllers: Rails 2's default routes
  # (map.connect ':controller/:action/:id') made every action reachable at
  # /<controller>/<action>. Modern Rails removed that catch-all, so the
  # actions referenced from the views are listed explicitly here.
  scope '/about', controller: 'about' do
    get :faq
    get :privacy
    get :rules
    get :press
  end

  scope '/admin', controller: 'admin' do
    get :buddy_icon
    get :fav_icon
    get :picture
  end

  scope '/briefing', controller: 'briefing' do
    get :contributors
    get :documents
    get :points
  end

  scope '/charts', controller: 'charts' do
    get :gainers_24hr
    get :gainers_7days
    get :gainers_30days
    get :issues
    get :losers_24hr
    get :losers_7days
    get :losers_30days
  end

  scope '/facebook', controller: 'facebook' do
    get :invite
    get :multiple
  end

  scope '/import', controller: 'import' do
    get :google
    get :windows
    get :yahoo
  end

  scope '/inbox', controller: 'inbox' do
    get :notifications
    get :sent
  end

  scope '/install', controller: 'install' do
    get :create
    get :create_admin_user
  end

  scope '/news', controller: 'news' do
    get :activities
    get :capital
    get :changes
    get :changes_activity
    get :changes_voting
    get :discussions
    get :obama
    get :points
    get :your_activities
    get :your_capital
    get :your_changes
    get :your_discussions
    get :your_followers_activities
    get :your_followers_capital
    get :your_followers_discussions
    get :your_followers_points
    get :your_network_activities
    get :your_network_capital
    get :your_network_discussions
    get :your_network_points
    get :your_points
    get :your_priorities_created_activities
    get :your_priorities_created_changes
    get :your_priorities_created_discussions
    get :your_priorities_created_obama
    get :your_priorities_created_points
    get :your_priority_activities
    get :your_priority_changes_activity
    get :your_priority_discussions
    get :your_priority_obama
    get :your_priority_points
  end

  scope '/prioritizer', controller: 'prioritizer' do
    get :same
    get :winner1
    get :winner2
  end

  scope '/twitter', controller: 'twitter' do
    get :create
  end

  scope '/vote', controller: 'vote' do
    get :no
    get :yes
  end

  # non restful routes
  get "/yours", to: "priorities#yours", as: "yours"
  get "/hot", to: "priorities#hot", as: "hot"
  get "/cold", to: "priorities#cold", as: "cold"
  get "/new", to: "priorities#new", as: "new"
  get "/controversial", to: "priorities#controversial", as: "controversial"

  # vote links emailed by the 2009 app: /vote/<choice>/<code>
  get "/vote/yes/:code",   to: "vote#yes",   as: "vote_yes"
  get "/vote/maybe/:code", to: "vote#maybe", as: "vote_maybe"
  get "/vote/no/:code",    to: "vote#no",    as: "vote_no"
  get "/splash", to: "splash#index", as: "splash"
  resources :issues, param: :slug
  # Sub-pages linked from the issues index/cloud (Rails 2 default-route era paths).
  get "issues/:slug/points",      to: "issues#points",      as: :issues_points
  get "issues/:slug/documents",   to: "issues#documents",   as: :issues_documents
  get "issues/:slug/discussions", to: "issues#discussions", as: :issues_discussions

  # Install the default routes as the lowest priority.
  resources :pictures, param: :short_name do
    member do
      # Explicit list of the sizes the pictures controller serves; the old
      # dynamic ":action" segment is deprecated (and removed in Rails 8.1).
      %w[get get_600 get_450 get_18_high icon_180 icon_140 icon_96 logo
         icon_48 icon_24 icon_16].each { |a| get a.to_sym }
    end
  end

  # ---------------------------------------------------------------------
  # Explicit replacements for the retired Rails-2 :controller/:action
  # catch-all. Generated from every controller action + every hash-style
  # (controller, action) URL-generation site in the app, so both generation
  # (redirect_to/url_for/link_to hashes) and serving keep working without
  # the dynamic segments removed in Rails 8.1.

  # Tag-scoped issue sub-pages, in both legacy shapes:
  #   /issues/<action>/<slug>  (what hash url_for used to generate)
  #   /issues/<slug>/<action>  (slug-first, matches the resources block above)
  get "issues/yours/:slug",   to: "issues#yours"
  get "issues/yours_finished/:slug",   to: "issues#yours_finished"
  get "issues/yours_created/:slug",   to: "issues#yours_created"
  get "issues/network/:slug",   to: "issues#network"
  get "issues/obama/:slug",   to: "issues#obama"
  get "issues/not_obama/:slug",   to: "issues#not_obama"
  get "issues/obama_opposed/:slug",   to: "issues#obama_opposed"
  get "issues/rising/:slug",   to: "issues#rising"
  get "issues/falling/:slug",   to: "issues#falling"
  get "issues/controversial/:slug",   to: "issues#controversial"
  get "issues/random/:slug",   to: "issues#random"
  get "issues/newest/:slug",   to: "issues#newest"
  get "issues/finished/:slug",   to: "issues#finished"
  get "issues/twitter/:slug",   to: "issues#twitter"
  get "issues/points/:slug",   to: "issues#points"
  get "issues/documents/:slug",   to: "issues#documents"
  get "issues/discussions/:slug",   to: "issues#discussions"

  get "issues/:slug/yours",   to: "issues#yours"
  get "issues/:slug/yours_finished",   to: "issues#yours_finished"
  get "issues/:slug/yours_created",   to: "issues#yours_created"
  get "issues/:slug/network",   to: "issues#network"
  get "issues/:slug/obama",   to: "issues#obama"
  get "issues/:slug/not_obama",   to: "issues#not_obama"
  get "issues/:slug/obama_opposed",   to: "issues#obama_opposed"
  get "issues/:slug/rising",   to: "issues#rising"
  get "issues/:slug/falling",   to: "issues#falling"
  get "issues/:slug/controversial",   to: "issues#controversial"
  get "issues/:slug/random",   to: "issues#random"
  get "issues/:slug/newest",   to: "issues#newest"
  get "issues/:slug/finished",   to: "issues#finished"
  get "issues/:slug/twitter",   to: "issues#twitter"
  get "issues/:slug/points",   to: "issues#points"
  get "issues/:slug/documents",   to: "issues#documents"
  get "issues/:slug/discussions",   to: "issues#discussions"

  # Full controller#action pair table (the catch-all's dispatch surface).
  match "about/faq(/:id)(.:format)", to: "about#faq", via: %i[get post]
  match "about/index(/:id)(.:format)", to: "about#index", via: %i[get post]
  match "about/press(/:id)(.:format)", to: "about#press", via: %i[get post]
  match "about/privacy(/:id)(.:format)", to: "about#privacy", via: %i[get post]
  match "about/rules(/:id)(.:format)", to: "about#rules", via: %i[get post]
  match "about/show(/:id)(.:format)", to: "about#show", via: %i[get post]
  match "about/stimulus(/:id)(.:format)", to: "about#stimulus", via: %i[get post]
  match "activities/destroy(/:id)(.:format)", to: "activities#destroy", via: %i[get post]
  match "activities/edit(/:id)(.:format)", to: "activities#edit", via: %i[get post]
  match "activities/index(/:id)(.:format)", to: "activities#index", via: %i[get post]
  match "activities/show(/:id)(.:format)", to: "activities#show", via: %i[get post]
  match "activities/undelete(/:id)(.:format)", to: "activities#undelete", via: %i[get post]
  match "activities/unhide(/:id)(.:format)", to: "activities#unhide", via: %i[get post]
  match "activities/update(/:id)(.:format)", to: "activities#update", via: %i[get post]
  match "admin/buddy_icon(/:id)(.:format)", to: "admin#buddy_icon", via: %i[get post]
  match "admin/buddy_icon_save(/:id)(.:format)", to: "admin#buddy_icon_save", via: %i[get post]
  match "admin/fav_icon(/:id)(.:format)", to: "admin#fav_icon", via: %i[get post]
  match "admin/fav_icon_save(/:id)(.:format)", to: "admin#fav_icon_save", via: %i[get post]
  match "admin/picture(/:id)(.:format)", to: "admin#picture", via: %i[get post]
  match "admin/picture_save(/:id)(.:format)", to: "admin#picture_save", via: %i[get post]
  match "admin/random_user(/:id)(.:format)", to: "admin#random_user", via: %i[get post]
  match "ads/create(/:id)(.:format)", to: "ads#create", via: %i[get post]
  match "ads/index(/:id)(.:format)", to: "ads#index", via: %i[get post]
  match "ads/new(/:id)(.:format)", to: "ads#new", via: %i[get post]
  match "ads/preview(/:id)(.:format)", to: "ads#preview", via: %i[get post]
  match "ads/show(/:id)(.:format)", to: "ads#show", via: %i[get post]
  match "ads/skip(/:id)(.:format)", to: "ads#skip", via: %i[get post]
  match "blurbs/create(/:id)(.:format)", to: "blurbs#create", via: %i[get post]
  match "blurbs/destroy(/:id)(.:format)", to: "blurbs#destroy", via: %i[get post]
  match "blurbs/edit(/:id)(.:format)", to: "blurbs#edit", via: %i[get post]
  match "blurbs/index(/:id)(.:format)", to: "blurbs#index", via: %i[get post]
  match "blurbs/new(/:id)(.:format)", to: "blurbs#new", via: %i[get post]
  match "blurbs/preview(/:id)(.:format)", to: "blurbs#preview", via: %i[get post]
  match "blurbs/update(/:id)(.:format)", to: "blurbs#update", via: %i[get post]
  match "branch_priorities/controversial(/:id)(.:format)", to: "branch_priorities#controversial", via: %i[get post]
  match "branch_priorities/falling(/:id)(.:format)", to: "branch_priorities#falling", via: %i[get post]
  match "branch_priorities/finished(/:id)(.:format)", to: "branch_priorities#finished", via: %i[get post]
  match "branch_priorities/list(/:id)(.:format)", to: "branch_priorities#list", via: %i[get post]
  match "branch_priorities/newest(/:id)(.:format)", to: "branch_priorities#newest", via: %i[get post]
  match "branch_priorities/random(/:id)(.:format)", to: "branch_priorities#random", via: %i[get post]
  match "branch_priorities/rising(/:id)(.:format)", to: "branch_priorities#rising", via: %i[get post]
  match "branch_priorities/top(/:id)(.:format)", to: "branch_priorities#top", via: %i[get post]
  match "branch_users/ambassadors(/:id)(.:format)", to: "branch_users#ambassadors", via: %i[get post]
  match "branch_users/index(/:id)(.:format)", to: "branch_users#index", via: %i[get post]
  match "branch_users/newest(/:id)(.:format)", to: "branch_users#newest", via: %i[get post]
  match "branch_users/params(/:id)(.:format)", to: "branch_users#params", via: %i[get post]
  match "branch_users/talkative(/:id)(.:format)", to: "branch_users#talkative", via: %i[get post]
  match "branch_users/twitterers(/:id)(.:format)", to: "branch_users#twitterers", via: %i[get post]
  match "branches/create(/:id)(.:format)", to: "branches#create", via: %i[get post]
  match "branches/default(/:id)(.:format)", to: "branches#default", via: %i[get post]
  match "branches/destroy(/:id)(.:format)", to: "branches#destroy", via: %i[get post]
  match "branches/edit(/:id)(.:format)", to: "branches#edit", via: %i[get post]
  match "branches/index(/:id)(.:format)", to: "branches#index", via: %i[get post]
  match "branches/new(/:id)(.:format)", to: "branches#new", via: %i[get post]
  match "branches/update(/:id)(.:format)", to: "branches#update", via: %i[get post]
  match "briefing/contributors(/:id)(.:format)", to: "briefing#contributors", via: %i[get post]
  match "briefing/documents(/:id)(.:format)", to: "briefing#documents", via: %i[get post]
  match "briefing/index(/:id)(.:format)", to: "briefing#index", via: %i[get post]
  match "briefing/points(/:id)(.:format)", to: "briefing#points", via: %i[get post]
  match "bulletins/create(/:id)(.:format)", to: "bulletins#create", via: %i[get post]
  match "bulletins/new_inline(/:id)(.:format)", to: "bulletins#new_inline", via: %i[get post]
  match "changes/activities(/:id)(.:format)", to: "changes#activities", via: %i[get post]
  match "changes/approve(/:id)(.:format)", to: "changes#approve", via: %i[get post]
  match "changes/create(/:id)(.:format)", to: "changes#create", via: %i[get post]
  match "changes/destroy(/:id)(.:format)", to: "changes#destroy", via: %i[get post]
  match "changes/edit(/:id)(.:format)", to: "changes#edit", via: %i[get post]
  match "changes/flip(/:id)(.:format)", to: "changes#flip", via: %i[get post]
  match "changes/index(/:id)(.:format)", to: "changes#index", via: %i[get post]
  match "changes/new(/:id)(.:format)", to: "changes#new", via: %i[get post]
  match "changes/show(/:id)(.:format)", to: "changes#show", via: %i[get post]
  match "changes/start(/:id)(.:format)", to: "changes#start", via: %i[get post]
  match "changes/stop(/:id)(.:format)", to: "changes#stop", via: %i[get post]
  match "changes/update(/:id)(.:format)", to: "changes#update", via: %i[get post]
  match "charts/gainers_24hr(/:id)(.:format)", to: "charts#gainers_24hr", via: %i[get post]
  match "charts/gainers_30days(/:id)(.:format)", to: "charts#gainers_30days", via: %i[get post]
  match "charts/gainers_7days(/:id)(.:format)", to: "charts#gainers_7days", via: %i[get post]
  match "charts/issues(/:id)(.:format)", to: "charts#issues", via: %i[get post]
  match "charts/losers_24hr(/:id)(.:format)", to: "charts#losers_24hr", via: %i[get post]
  match "charts/losers_30days(/:id)(.:format)", to: "charts#losers_30days", via: %i[get post]
  match "charts/losers_7days(/:id)(.:format)", to: "charts#losers_7days", via: %i[get post]
  match "color_schemes/create(/:id)(.:format)", to: "color_schemes#create", via: %i[get post]
  match "color_schemes/destroy(/:id)(.:format)", to: "color_schemes#destroy", via: %i[get post]
  match "color_schemes/edit(/:id)(.:format)", to: "color_schemes#edit", via: %i[get post]
  match "color_schemes/index(/:id)(.:format)", to: "color_schemes#index", via: %i[get post]
  match "color_schemes/new(/:id)(.:format)", to: "color_schemes#new", via: %i[get post]
  match "color_schemes/preview(/:id)(.:format)", to: "color_schemes#preview", via: %i[get post]
  match "color_schemes/show(/:id)(.:format)", to: "color_schemes#show", via: %i[get post]
  match "color_schemes/update(/:id)(.:format)", to: "color_schemes#update", via: %i[get post]
  match "comments/abusive(/:id)(.:format)", to: "comments#abusive", via: %i[get post]
  match "comments/create(/:id)(.:format)", to: "comments#create", via: %i[get post]
  match "comments/destroy(/:id)(.:format)", to: "comments#destroy", via: %i[get post]
  match "comments/edit(/:id)(.:format)", to: "comments#edit", via: %i[get post]
  match "comments/flag(/:id)(.:format)", to: "comments#flag", via: %i[get post]
  match "comments/index(/:id)(.:format)", to: "comments#index", via: %i[get post]
  match "comments/more(/:id)(.:format)", to: "comments#more", via: %i[get post]
  match "comments/new(/:id)(.:format)", to: "comments#new", via: %i[get post]
  match "comments/not_abusive(/:id)(.:format)", to: "comments#not_abusive", via: %i[get post]
  match "comments/show(/:id)(.:format)", to: "comments#show", via: %i[get post]
  match "comments/unhide(/:id)(.:format)", to: "comments#unhide", via: %i[get post]
  match "comments/update(/:id)(.:format)", to: "comments#update", via: %i[get post]
  match "constituents/get_legislator(/:id)(.:format)", to: "constituents#get_legislator", via: %i[get post]
  match "constituents/index(/:id)(.:format)", to: "constituents#index", via: %i[get post]
  match "constituents/priorities(/:id)(.:format)", to: "constituents#priorities", via: %i[get post]
  match "constituents/show(/:id)(.:format)", to: "constituents#show", via: %i[get post]
  match "delayed_jobs/clear(/:id)(.:format)", to: "delayed_jobs#clear", via: %i[get post]
  match "delayed_jobs/create(/:id)(.:format)", to: "delayed_jobs#create", via: %i[get post]
  match "delayed_jobs/destroy(/:id)(.:format)", to: "delayed_jobs#destroy", via: %i[get post]
  match "delayed_jobs/edit(/:id)(.:format)", to: "delayed_jobs#edit", via: %i[get post]
  match "delayed_jobs/index(/:id)(.:format)", to: "delayed_jobs#index", via: %i[get post]
  match "delayed_jobs/new(/:id)(.:format)", to: "delayed_jobs#new", via: %i[get post]
  match "delayed_jobs/show(/:id)(.:format)", to: "delayed_jobs#show", via: %i[get post]
  match "delayed_jobs/top(/:id)(.:format)", to: "delayed_jobs#top", via: %i[get post]
  match "delayed_jobs/update(/:id)(.:format)", to: "delayed_jobs#update", via: %i[get post]
  match "document_revisions/clean(/:id)(.:format)", to: "document_revisions#clean", via: %i[get post]
  match "document_revisions/create(/:id)(.:format)", to: "document_revisions#create", via: %i[get post]
  match "document_revisions/destroy(/:id)(.:format)", to: "document_revisions#destroy", via: %i[get post]
  match "document_revisions/edit(/:id)(.:format)", to: "document_revisions#edit", via: %i[get post]
  match "document_revisions/index(/:id)(.:format)", to: "document_revisions#index", via: %i[get post]
  match "document_revisions/new(/:id)(.:format)", to: "document_revisions#new", via: %i[get post]
  match "document_revisions/show(/:id)(.:format)", to: "document_revisions#show", via: %i[get post]
  match "document_revisions/update(/:id)(.:format)", to: "document_revisions#update", via: %i[get post]
  match "documents/activity(/:id)(.:format)", to: "documents#activity", via: %i[get post]
  match "documents/create(/:id)(.:format)", to: "documents#create", via: %i[get post]
  match "documents/destroy(/:id)(.:format)", to: "documents#destroy", via: %i[get post]
  match "documents/discussions(/:id)(.:format)", to: "documents#discussions", via: %i[get post]
  match "documents/edit(/:id)(.:format)", to: "documents#edit", via: %i[get post]
  match "documents/index(/:id)(.:format)", to: "documents#index", via: %i[get post]
  match "documents/new(/:id)(.:format)", to: "documents#new", via: %i[get post]
  match "documents/newest(/:id)(.:format)", to: "documents#newest", via: %i[get post]
  match "documents/quality(/:id)(.:format)", to: "documents#quality", via: %i[get post]
  match "documents/revised(/:id)(.:format)", to: "documents#revised", via: %i[get post]
  match "documents/show(/:id)(.:format)", to: "documents#show", via: %i[get post]
  match "documents/unhide(/:id)(.:format)", to: "documents#unhide", via: %i[get post]
  match "documents/unquality(/:id)(.:format)", to: "documents#unquality", via: %i[get post]
  match "documents/update(/:id)(.:format)", to: "documents#update", via: %i[get post]
  match "documents/your_priorities(/:id)(.:format)", to: "documents#your_priorities", via: %i[get post]
  match "email_templates/create(/:id)(.:format)", to: "email_templates#create", via: %i[get post]
  match "email_templates/destroy(/:id)(.:format)", to: "email_templates#destroy", via: %i[get post]
  match "email_templates/edit(/:id)(.:format)", to: "email_templates#edit", via: %i[get post]
  match "email_templates/index(/:id)(.:format)", to: "email_templates#index", via: %i[get post]
  match "email_templates/new(/:id)(.:format)", to: "email_templates#new", via: %i[get post]
  match "email_templates/update(/:id)(.:format)", to: "email_templates#update", via: %i[get post]
  match "endorsements/destroy(/:id)(.:format)", to: "endorsements#destroy", via: %i[get post]
  match "endorsements/edit(/:id)(.:format)", to: "endorsements#edit", via: %i[get post]
  match "endorsements/index(/:id)(.:format)", to: "endorsements#index", via: %i[get post]
  match "endorsements/update(/:id)(.:format)", to: "endorsements#update", via: %i[get post]
  match "export/stratml(/:id)(.:format)", to: "export#stratml", via: %i[get post]
  match "facebook/invite(/:id)(.:format)", to: "facebook#invite", via: %i[get post]
  match "facebook/multiple(/:id)(.:format)", to: "facebook#multiple", via: %i[get post]
  match "following_discussions/create(/:id)(.:format)", to: "following_discussions#create", via: %i[get post]
  match "following_discussions/destroy(/:id)(.:format)", to: "following_discussions#destroy", via: %i[get post]
  match "following_discussions/index(/:id)(.:format)", to: "following_discussions#index", via: %i[get post]
  match "following_discussions/new(/:id)(.:format)", to: "following_discussions#new", via: %i[get post]
  match "followings/create(/:id)(.:format)", to: "followings#create", via: %i[get post]
  match "followings/destroy(/:id)(.:format)", to: "followings#destroy", via: %i[get post]
  match "followings/edit(/:id)(.:format)", to: "followings#edit", via: %i[get post]
  match "followings/index(/:id)(.:format)", to: "followings#index", via: %i[get post]
  match "followings/multiple(/:id)(.:format)", to: "followings#multiple", via: %i[get post]
  match "followings/new(/:id)(.:format)", to: "followings#new", via: %i[get post]
  match "followings/show(/:id)(.:format)", to: "followings#show", via: %i[get post]
  match "followings/update(/:id)(.:format)", to: "followings#update", via: %i[get post]
  match "governments/apis(/:id)(.:format)", to: "governments#apis", via: %i[get post]
  match "governments/edit(/:id)(.:format)", to: "governments#edit", via: %i[get post]
  match "governments/update(/:id)(.:format)", to: "governments#update", via: %i[get post]
  match "home/top_issues(/:id)(.:format)", to: "home#top_issues", via: %i[get post]
  match "import/google(/:id)(.:format)", to: "import#google", via: %i[get post]
  match "import/status(/:id)(.:format)", to: "import#status", via: %i[get post]
  match "import/windows(/:id)(.:format)", to: "import#windows", via: %i[get post]
  match "import/yahoo(/:id)(.:format)", to: "import#yahoo", via: %i[get post]
  match "inbox/index(/:id)(.:format)", to: "inbox#index", via: %i[get post]
  match "inbox/not(/:id)(.:format)", to: "inbox#not", via: %i[get post]
  match "inbox/notifications(/:id)(.:format)", to: "inbox#notifications", via: %i[get post]
  match "inbox/sent(/:id)(.:format)", to: "inbox#sent", via: %i[get post]
  match "install/admin_user(/:id)(.:format)", to: "install#admin_user", via: %i[get post]
  match "install/create(/:id)(.:format)", to: "install#create", via: %i[get post]
  match "install/create_admin_user(/:id)(.:format)", to: "install#create_admin_user", via: %i[get post]
  match "install/index(/:id)(.:format)", to: "install#index", via: %i[get post]
  match "issues/controversial(/:id)(.:format)", to: "issues#controversial", via: %i[get post]
  match "issues/discussions(/:id)(.:format)", to: "issues#discussions", via: %i[get post]
  match "issues/documents(/:id)(.:format)", to: "issues#documents", via: %i[get post]
  match "issues/falling(/:id)(.:format)", to: "issues#falling", via: %i[get post]
  match "issues/finished(/:id)(.:format)", to: "issues#finished", via: %i[get post]
  match "issues/index(/:id)(.:format)", to: "issues#index", via: %i[get post]
  match "issues/list(/:id)(.:format)", to: "issues#list", via: %i[get post]
  match "issues/network(/:id)(.:format)", to: "issues#network", via: %i[get post]
  match "issues/newest(/:id)(.:format)", to: "issues#newest", via: %i[get post]
  match "issues/not_obama(/:id)(.:format)", to: "issues#not_obama", via: %i[get post]
  match "issues/obama(/:id)(.:format)", to: "issues#obama", via: %i[get post]
  match "issues/obama_opposed(/:id)(.:format)", to: "issues#obama_opposed", via: %i[get post]
  match "issues/points(/:id)(.:format)", to: "issues#points", via: %i[get post]
  match "issues/random(/:id)(.:format)", to: "issues#random", via: %i[get post]
  match "issues/rising(/:id)(.:format)", to: "issues#rising", via: %i[get post]
  match "issues/show(/:id)(.:format)", to: "issues#show", via: %i[get post]
  match "issues/twitter(/:id)(.:format)", to: "issues#twitter", via: %i[get post]
  match "issues/yours(/:id)(.:format)", to: "issues#yours", via: %i[get post]
  match "issues/yours_created(/:id)(.:format)", to: "issues#yours_created", via: %i[get post]
  match "issues/yours_finished(/:id)(.:format)", to: "issues#yours_finished", via: %i[get post]
  match "legislators/index(/:id)(.:format)", to: "legislators#index", via: %i[get post]
  match "legislators/priorities(/:id)(.:format)", to: "legislators#priorities", via: %i[get post]
  match "legislators/show(/:id)(.:format)", to: "legislators#show", via: %i[get post]
  match "messages/create(/:id)(.:format)", to: "messages#create", via: %i[get post]
  match "messages/index(/:id)(.:format)", to: "messages#index", via: %i[get post]
  match "messages/new(/:id)(.:format)", to: "messages#new", via: %i[get post]
  match "network/ambassadors(/:id)(.:format)", to: "network#ambassadors", via: %i[get post]
  match "network/deleted(/:id)(.:format)", to: "network#deleted", via: %i[get post]
  match "network/find(/:id)(.:format)", to: "network#find", via: %i[get post]
  match "network/index(/:id)(.:format)", to: "network#index", via: %i[get post]
  match "network/list(/:id)(.:format)", to: "network#list", via: %i[get post]
  match "network/newest(/:id)(.:format)", to: "network#newest", via: %i[get post]
  match "network/params(/:id)(.:format)", to: "network#params", via: %i[get post]
  match "network/partners(/:id)(.:format)", to: "network#partners", via: %i[get post]
  match "network/probation(/:id)(.:format)", to: "network#probation", via: %i[get post]
  match "network/search(/:id)(.:format)", to: "network#search", via: %i[get post]
  match "network/suspended(/:id)(.:format)", to: "network#suspended", via: %i[get post]
  match "network/talkative(/:id)(.:format)", to: "network#talkative", via: %i[get post]
  match "network/twitterers(/:id)(.:format)", to: "network#twitterers", via: %i[get post]
  match "network/unverified(/:id)(.:format)", to: "network#unverified", via: %i[get post]
  match "network/warnings(/:id)(.:format)", to: "network#warnings", via: %i[get post]
  match "news/activities(/:id)(.:format)", to: "news#activities", via: %i[get post]
  match "news/activity_list(/:id)(.:format)", to: "news#activity_list", via: %i[get post]
  match "news/capital(/:id)(.:format)", to: "news#capital", via: %i[get post]
  match "news/change_list(/:id)(.:format)", to: "news#change_list", via: %i[get post]
  match "news/changes(/:id)(.:format)", to: "news#changes", via: %i[get post]
  match "news/changes_activity(/:id)(.:format)", to: "news#changes_activity", via: %i[get post]
  match "news/changes_voting(/:id)(.:format)", to: "news#changes_voting", via: %i[get post]
  match "news/comments(/:id)(.:format)", to: "news#comments", via: %i[get post]
  match "news/discussions(/:id)(.:format)", to: "news#discussions", via: %i[get post]
  match "news/index(/:id)(.:format)", to: "news#index", via: %i[get post]
  match "news/obama(/:id)(.:format)", to: "news#obama", via: %i[get post]
  match "news/points(/:id)(.:format)", to: "news#points", via: %i[get post]
  match "news/videos(/:id)(.:format)", to: "news#videos", via: %i[get post]
  match "news/your_activities(/:id)(.:format)", to: "news#your_activities", via: %i[get post]
  match "news/your_capital(/:id)(.:format)", to: "news#your_capital", via: %i[get post]
  match "news/your_changes(/:id)(.:format)", to: "news#your_changes", via: %i[get post]
  match "news/your_discussions(/:id)(.:format)", to: "news#your_discussions", via: %i[get post]
  match "news/your_followers_activities(/:id)(.:format)", to: "news#your_followers_activities", via: %i[get post]
  match "news/your_followers_capital(/:id)(.:format)", to: "news#your_followers_capital", via: %i[get post]
  match "news/your_followers_changes(/:id)(.:format)", to: "news#your_followers_changes", via: %i[get post]
  match "news/your_followers_discussions(/:id)(.:format)", to: "news#your_followers_discussions", via: %i[get post]
  match "news/your_followers_points(/:id)(.:format)", to: "news#your_followers_points", via: %i[get post]
  match "news/your_network_activities(/:id)(.:format)", to: "news#your_network_activities", via: %i[get post]
  match "news/your_network_capital(/:id)(.:format)", to: "news#your_network_capital", via: %i[get post]
  match "news/your_network_changes(/:id)(.:format)", to: "news#your_network_changes", via: %i[get post]
  match "news/your_network_discussions(/:id)(.:format)", to: "news#your_network_discussions", via: %i[get post]
  match "news/your_network_points(/:id)(.:format)", to: "news#your_network_points", via: %i[get post]
  match "news/your_points(/:id)(.:format)", to: "news#your_points", via: %i[get post]
  match "news/your_priorities_created_activities(/:id)(.:format)", to: "news#your_priorities_created_activities", via: %i[get post]
  match "news/your_priorities_created_changes(/:id)(.:format)", to: "news#your_priorities_created_changes", via: %i[get post]
  match "news/your_priorities_created_discussions(/:id)(.:format)", to: "news#your_priorities_created_discussions", via: %i[get post]
  match "news/your_priorities_created_obama(/:id)(.:format)", to: "news#your_priorities_created_obama", via: %i[get post]
  match "news/your_priorities_created_points(/:id)(.:format)", to: "news#your_priorities_created_points", via: %i[get post]
  match "news/your_priority_activities(/:id)(.:format)", to: "news#your_priority_activities", via: %i[get post]
  match "news/your_priority_changes(/:id)(.:format)", to: "news#your_priority_changes", via: %i[get post]
  match "news/your_priority_changes_activity(/:id)(.:format)", to: "news#your_priority_changes_activity", via: %i[get post]
  match "news/your_priority_changes_voting(/:id)(.:format)", to: "news#your_priority_changes_voting", via: %i[get post]
  match "news/your_priority_discussions(/:id)(.:format)", to: "news#your_priority_discussions", via: %i[get post]
  match "news/your_priority_obama(/:id)(.:format)", to: "news#your_priority_obama", via: %i[get post]
  match "news/your_priority_points(/:id)(.:format)", to: "news#your_priority_points", via: %i[get post]
  match "notifications/destroy(/:id)(.:format)", to: "notifications#destroy", via: %i[get post]
  match "notifications/show(/:id)(.:format)", to: "notifications#show", via: %i[get post]
  match "pages/create(/:id)(.:format)", to: "pages#create", via: %i[get post]
  match "pages/destroy(/:id)(.:format)", to: "pages#destroy", via: %i[get post]
  match "pages/edit(/:id)(.:format)", to: "pages#edit", via: %i[get post]
  match "pages/index(/:id)(.:format)", to: "pages#index", via: %i[get post]
  match "pages/new(/:id)(.:format)", to: "pages#new", via: %i[get post]
  match "pages/update(/:id)(.:format)", to: "pages#update", via: %i[get post]
  match "partners/create(/:id)(.:format)", to: "partners#create", via: %i[get post]
  match "partners/destroy(/:id)(.:format)", to: "partners#destroy", via: %i[get post]
  match "partners/edit(/:id)(.:format)", to: "partners#edit", via: %i[get post]
  match "partners/email(/:id)(.:format)", to: "partners#email", via: %i[get post]
  match "partners/index(/:id)(.:format)", to: "partners#index", via: %i[get post]
  match "partners/new(/:id)(.:format)", to: "partners#new", via: %i[get post]
  match "partners/picture(/:id)(.:format)", to: "partners#picture", via: %i[get post]
  match "partners/picture_save(/:id)(.:format)", to: "partners#picture_save", via: %i[get post]
  match "partners/show(/:id)(.:format)", to: "partners#show", via: %i[get post]
  match "partners/signup(/:id)(.:format)", to: "partners#signup", via: %i[get post]
  match "partners/update(/:id)(.:format)", to: "partners#update", via: %i[get post]
  match "passwords/create(/:id)(.:format)", to: "passwords#create", via: %i[get post]
  match "passwords/edit(/:id)(.:format)", to: "passwords#edit", via: %i[get post]
  match "passwords/new(/:id)(.:format)", to: "passwords#new", via: %i[get post]
  match "passwords/update(/:id)(.:format)", to: "passwords#update", via: %i[get post]
  match "pictures/get(/:id)(.:format)", to: "pictures#get", via: %i[get post]
  match "pictures/get_18_high(/:id)(.:format)", to: "pictures#get_18_high", via: %i[get post]
  match "pictures/get_450(/:id)(.:format)", to: "pictures#get_450", via: %i[get post]
  match "pictures/get_600(/:id)(.:format)", to: "pictures#get_600", via: %i[get post]
  match "pictures/icon_140(/:id)(.:format)", to: "pictures#icon_140", via: %i[get post]
  match "pictures/icon_16(/:id)(.:format)", to: "pictures#icon_16", via: %i[get post]
  match "pictures/icon_180(/:id)(.:format)", to: "pictures#icon_180", via: %i[get post]
  match "pictures/icon_24(/:id)(.:format)", to: "pictures#icon_24", via: %i[get post]
  match "pictures/icon_48(/:id)(.:format)", to: "pictures#icon_48", via: %i[get post]
  match "pictures/icon_96(/:id)(.:format)", to: "pictures#icon_96", via: %i[get post]
  match "pictures/logo(/:id)(.:format)", to: "pictures#logo", via: %i[get post]
  match "points/activity(/:id)(.:format)", to: "points#activity", via: %i[get post]
  match "points/create(/:id)(.:format)", to: "points#create", via: %i[get post]
  match "points/destroy(/:id)(.:format)", to: "points#destroy", via: %i[get post]
  match "points/discussions(/:id)(.:format)", to: "points#discussions", via: %i[get post]
  match "points/edit(/:id)(.:format)", to: "points#edit", via: %i[get post]
  match "points/index(/:id)(.:format)", to: "points#index", via: %i[get post]
  match "points/new(/:id)(.:format)", to: "points#new", via: %i[get post]
  match "points/newest(/:id)(.:format)", to: "points#newest", via: %i[get post]
  match "points/quality(/:id)(.:format)", to: "points#quality", via: %i[get post]
  match "points/revised(/:id)(.:format)", to: "points#revised", via: %i[get post]
  match "points/show(/:id)(.:format)", to: "points#show", via: %i[get post]
  match "points/unhide(/:id)(.:format)", to: "points#unhide", via: %i[get post]
  match "points/unquality(/:id)(.:format)", to: "points#unquality", via: %i[get post]
  match "points/update(/:id)(.:format)", to: "points#update", via: %i[get post]
  match "points/your_priorities(/:id)(.:format)", to: "points#your_priorities", via: %i[get post]
  match "priorities/activities(/:id)(.:format)", to: "priorities#activities", via: %i[get post]
  match "priorities/ads(/:id)(.:format)", to: "priorities#ads", via: %i[get post]
  match "priorities/bury(/:id)(.:format)", to: "priorities#bury", via: %i[get post]
  match "priorities/comments(/:id)(.:format)", to: "priorities#comments", via: %i[get post]
  match "priorities/compromised(/:id)(.:format)", to: "priorities#compromised", via: %i[get post]
  match "priorities/consider(/:id)(.:format)", to: "priorities#consider", via: %i[get post]
  match "priorities/controversial(/:id)(.:format)", to: "priorities#controversial", via: %i[get post]
  match "priorities/create(/:id)(.:format)", to: "priorities#create", via: %i[get post]
  match "priorities/create_short_url(/:id)(.:format)", to: "priorities#create_short_url", via: %i[get post]
  match "priorities/current_government(/:id)(.:format)", to: "priorities#current_government", via: %i[get post]
  match "priorities/destroy(/:id)(.:format)", to: "priorities#destroy", via: %i[get post]
  match "priorities/discussions(/:id)(.:format)", to: "priorities#discussions", via: %i[get post]
  match "priorities/documents(/:id)(.:format)", to: "priorities#documents", via: %i[get post]
  match "priorities/edit(/:id)(.:format)", to: "priorities#edit", via: %i[get post]
  match "priorities/endorse(/:id)(.:format)", to: "priorities#endorse", via: %i[get post]
  match "priorities/endorsed(/:id)(.:format)", to: "priorities#endorsed", via: %i[get post]
  match "priorities/endorser_documents(/:id)(.:format)", to: "priorities#endorser_documents", via: %i[get post]
  match "priorities/endorser_points(/:id)(.:format)", to: "priorities#endorser_points", via: %i[get post]
  match "priorities/endorsers(/:id)(.:format)", to: "priorities#endorsers", via: %i[get post]
  match "priorities/everyone_documents(/:id)(.:format)", to: "priorities#everyone_documents", via: %i[get post]
  match "priorities/everyone_points(/:id)(.:format)", to: "priorities#everyone_points", via: %i[get post]
  match "priorities/failed(/:id)(.:format)", to: "priorities#failed", via: %i[get post]
  match "priorities/falling(/:id)(.:format)", to: "priorities#falling", via: %i[get post]
  match "priorities/finished(/:id)(.:format)", to: "priorities#finished", via: %i[get post]
  match "priorities/flag_inappropriate(/:id)(.:format)", to: "priorities#flag_inappropriate", via: %i[get post]
  match "priorities/index(/:id)(.:format)", to: "priorities#index", via: %i[get post]
  match "priorities/intheworks(/:id)(.:format)", to: "priorities#intheworks", via: %i[get post]
  match "priorities/list(/:id)(.:format)", to: "priorities#list", via: %i[get post]
  match "priorities/network(/:id)(.:format)", to: "priorities#network", via: %i[get post]
  match "priorities/neutral_documents(/:id)(.:format)", to: "priorities#neutral_documents", via: %i[get post]
  match "priorities/neutral_points(/:id)(.:format)", to: "priorities#neutral_points", via: %i[get post]
  match "priorities/new(/:id)(.:format)", to: "priorities#new", via: %i[get post]
  match "priorities/newest(/:id)(.:format)", to: "priorities#newest", via: %i[get post]
  match "priorities/not_obama(/:id)(.:format)", to: "priorities#not_obama", via: %i[get post]
  match "priorities/obama(/:id)(.:format)", to: "priorities#obama", via: %i[get post]
  match "priorities/obama_opposed(/:id)(.:format)", to: "priorities#obama_opposed", via: %i[get post]
  match "priorities/opposed(/:id)(.:format)", to: "priorities#opposed", via: %i[get post]
  match "priorities/opposer_documents(/:id)(.:format)", to: "priorities#opposer_documents", via: %i[get post]
  match "priorities/opposer_points(/:id)(.:format)", to: "priorities#opposer_points", via: %i[get post]
  match "priorities/opposers(/:id)(.:format)", to: "priorities#opposers", via: %i[get post]
  match "priorities/points(/:id)(.:format)", to: "priorities#points", via: %i[get post]
  match "priorities/random(/:id)(.:format)", to: "priorities#random", via: %i[get post]
  match "priorities/rising(/:id)(.:format)", to: "priorities#rising", via: %i[get post]
  match "priorities/show(/:id)(.:format)", to: "priorities#show", via: %i[get post]
  match "priorities/successful(/:id)(.:format)", to: "priorities#successful", via: %i[get post]
  match "priorities/tag(/:id)(.:format)", to: "priorities#tag", via: %i[get post]
  match "priorities/tag_save(/:id)(.:format)", to: "priorities#tag_save", via: %i[get post]
  match "priorities/top(/:id)(.:format)", to: "priorities#top", via: %i[get post]
  match "priorities/untagged(/:id)(.:format)", to: "priorities#untagged", via: %i[get post]
  match "priorities/update(/:id)(.:format)", to: "priorities#update", via: %i[get post]
  match "priorities/yours(/:id)(.:format)", to: "priorities#yours", via: %i[get post]
  match "priorities/yours_ads(/:id)(.:format)", to: "priorities#yours_ads", via: %i[get post]
  match "priorities/yours_created(/:id)(.:format)", to: "priorities#yours_created", via: %i[get post]
  match "priorities/yours_finished(/:id)(.:format)", to: "priorities#yours_finished", via: %i[get post]
  match "priorities/yours_lowest(/:id)(.:format)", to: "priorities#yours_lowest", via: %i[get post]
  match "priorities/yours_top(/:id)(.:format)", to: "priorities#yours_top", via: %i[get post]
  match "prioritizer/endorse(/:id)(.:format)", to: "prioritizer#endorse", via: %i[get post]
  match "prioritizer/index(/:id)(.:format)", to: "prioritizer#index", via: %i[get post]
  match "prioritizer/same(/:id)(.:format)", to: "prioritizer#same", via: %i[get post]
  match "prioritizer/skip(/:id)(.:format)", to: "prioritizer#skip", via: %i[get post]
  match "prioritizer/winner1(/:id)(.:format)", to: "prioritizer#winner1", via: %i[get post]
  match "prioritizer/winner2(/:id)(.:format)", to: "prioritizer#winner2", via: %i[get post]
  match "profiles/create(/:id)(.:format)", to: "profiles#create", via: %i[get post]
  match "profiles/destroy(/:id)(.:format)", to: "profiles#destroy", via: %i[get post]
  match "profiles/edit(/:id)(.:format)", to: "profiles#edit", via: %i[get post]
  match "profiles/new(/:id)(.:format)", to: "profiles#new", via: %i[get post]
  match "profiles/profiles(/:id)(.:format)", to: "profiles#profiles", via: %i[get post]
  match "profiles/show(/:id)(.:format)", to: "profiles#show", via: %i[get post]
  match "profiles/update(/:id)(.:format)", to: "profiles#update", via: %i[get post]
  match "revisions/clean(/:id)(.:format)", to: "revisions#clean", via: %i[get post]
  match "revisions/create(/:id)(.:format)", to: "revisions#create", via: %i[get post]
  match "revisions/destroy(/:id)(.:format)", to: "revisions#destroy", via: %i[get post]
  match "revisions/edit(/:id)(.:format)", to: "revisions#edit", via: %i[get post]
  match "revisions/index(/:id)(.:format)", to: "revisions#index", via: %i[get post]
  match "revisions/new(/:id)(.:format)", to: "revisions#new", via: %i[get post]
  match "revisions/show(/:id)(.:format)", to: "revisions#show", via: %i[get post]
  match "revisions/update(/:id)(.:format)", to: "revisions#update", via: %i[get post]
  match "rss/your_comments(/:id)(.:format)", to: "rss#your_comments", via: %i[get post]
  match "rss/your_not(/:id)(.:format)", to: "rss#your_not", via: %i[get post]
  match "rss/your_notifications(/:id)(.:format)", to: "rss#your_notifications", via: %i[get post]
  match "rss/your_priorities_created_activities(/:id)(.:format)", to: "rss#your_priorities_created_activities", via: %i[get post]
  match "searches/documents(/:id)(.:format)", to: "searches#documents", via: %i[get post]
  match "searches/index(/:id)(.:format)", to: "searches#index", via: %i[get post]
  match "searches/points(/:id)(.:format)", to: "searches#points", via: %i[get post]
  match "sessions/create(/:id)(.:format)", to: "sessions#create", via: %i[get post]
  match "sessions/destroy(/:id)(.:format)", to: "sessions#destroy", via: %i[get post]
  match "sessions/new(/:id)(.:format)", to: "sessions#new", via: %i[get post]
  match "settings/branch_change(/:id)(.:format)", to: "settings#branch_change", via: %i[get post]
  match "settings/delete(/:id)(.:format)", to: "settings#delete", via: %i[get post]
  match "settings/destroy(/:id)(.:format)", to: "settings#destroy", via: %i[get post]
  match "settings/index(/:id)(.:format)", to: "settings#index", via: %i[get post]
  match "settings/legislators(/:id)(.:format)", to: "settings#legislators", via: %i[get post]
  match "settings/legislators_save(/:id)(.:format)", to: "settings#legislators_save", via: %i[get post]
  match "settings/picture(/:id)(.:format)", to: "settings#picture", via: %i[get post]
  match "settings/picture_save(/:id)(.:format)", to: "settings#picture_save", via: %i[get post]
  match "settings/signups(/:id)(.:format)", to: "settings#signups", via: %i[get post]
  match "settings/update(/:id)(.:format)", to: "settings#update", via: %i[get post]
  match "signups/create(/:id)(.:format)", to: "signups#create", via: %i[get post]
  match "signups/destroy(/:id)(.:format)", to: "signups#destroy", via: %i[get post]
  match "signups/edit(/:id)(.:format)", to: "signups#edit", via: %i[get post]
  match "signups/index(/:id)(.:format)", to: "signups#index", via: %i[get post]
  match "signups/new(/:id)(.:format)", to: "signups#new", via: %i[get post]
  match "signups/show(/:id)(.:format)", to: "signups#show", via: %i[get post]
  match "signups/update(/:id)(.:format)", to: "signups#update", via: %i[get post]
  match "splash/index(/:id)(.:format)", to: "splash#index", via: %i[get post]
  match "tags/create(/:id)(.:format)", to: "tags#create", via: %i[get post]
  match "tags/destroy(/:id)(.:format)", to: "tags#destroy", via: %i[get post]
  match "tags/edit(/:id)(.:format)", to: "tags#edit", via: %i[get post]
  match "tags/get_all(/:id)(.:format)", to: "tags#get_all", via: %i[get post]
  match "tags/index(/:id)(.:format)", to: "tags#index", via: %i[get post]
  match "tags/new(/:id)(.:format)", to: "tags#new", via: %i[get post]
  match "tags/show(/:id)(.:format)", to: "tags#show", via: %i[get post]
  match "tags/update(/:id)(.:format)", to: "tags#update", via: %i[get post]
  match "twitter/callback(/:id)(.:format)", to: "twitter#callback", via: %i[get post]
  match "twitter/connected(/:id)(.:format)", to: "twitter#connected", via: %i[get post]
  match "twitter/create(/:id)(.:format)", to: "twitter#create", via: %i[get post]
  match "twitter/failed(/:id)(.:format)", to: "twitter#failed", via: %i[get post]
  match "twitter/success(/:id)(.:format)", to: "twitter#success", via: %i[get post]
  match "unsubscribes/create(/:id)(.:format)", to: "unsubscribes#create", via: %i[get post]
  match "unsubscribes/new(/:id)(.:format)", to: "unsubscribes#new", via: %i[get post]
  match "user_contacts/create(/:id)(.:format)", to: "user_contacts#create", via: %i[get post]
  match "user_contacts/following(/:id)(.:format)", to: "user_contacts#following", via: %i[get post]
  match "user_contacts/index(/:id)(.:format)", to: "user_contacts#index", via: %i[get post]
  match "user_contacts/invited(/:id)(.:format)", to: "user_contacts#invited", via: %i[get post]
  match "user_contacts/members(/:id)(.:format)", to: "user_contacts#members", via: %i[get post]
  match "user_contacts/multiple(/:id)(.:format)", to: "user_contacts#multiple", via: %i[get post]
  match "user_contacts/new(/:id)(.:format)", to: "user_contacts#new", via: %i[get post]
  match "user_contacts/not_invited(/:id)(.:format)", to: "user_contacts#not_invited", via: %i[get post]
  match "users/activate(/:id)(.:format)", to: "users#activate", via: %i[get post]
  match "users/activities(/:id)(.:format)", to: "users#activities", via: %i[get post]
  match "users/ads(/:id)(.:format)", to: "users#ads", via: %i[get post]
  match "users/capital(/:id)(.:format)", to: "users#capital", via: %i[get post]
  match "users/comments(/:id)(.:format)", to: "users#comments", via: %i[get post]
  match "users/create(/:id)(.:format)", to: "users#create", via: %i[get post]
  match "users/discussions(/:id)(.:format)", to: "users#discussions", via: %i[get post]
  match "users/documents(/:id)(.:format)", to: "users#documents", via: %i[get post]
  match "users/edit(/:id)(.:format)", to: "users#edit", via: %i[get post]
  match "users/endorse(/:id)(.:format)", to: "users#endorse", via: %i[get post]
  match "users/endorsements(/:id)(.:format)", to: "users#endorsements", via: %i[get post]
  match "users/follow(/:id)(.:format)", to: "users#follow", via: %i[get post]
  match "users/followers(/:id)(.:format)", to: "users#followers", via: %i[get post]
  match "users/following(/:id)(.:format)", to: "users#following", via: %i[get post]
  match "users/ignorers(/:id)(.:format)", to: "users#ignorers", via: %i[get post]
  match "users/ignoring(/:id)(.:format)", to: "users#ignoring", via: %i[get post]
  match "users/impersonate(/:id)(.:format)", to: "users#impersonate", via: %i[get post]
  match "users/index(/:id)(.:format)", to: "users#index", via: %i[get post]
  match "users/legislators(/:id)(.:format)", to: "users#legislators", via: %i[get post]
  match "users/legislators_save(/:id)(.:format)", to: "users#legislators_save", via: %i[get post]
  match "users/make_admin(/:id)(.:format)", to: "users#make_admin", via: %i[get post]
  match "users/new(/:id)(.:format)", to: "users#new", via: %i[get post]
  match "users/order(/:id)(.:format)", to: "users#order", via: %i[get post]
  match "users/points(/:id)(.:format)", to: "users#points", via: %i[get post]
  match "users/priorities(/:id)(.:format)", to: "users#priorities", via: %i[get post]
  match "users/resend_activation(/:id)(.:format)", to: "users#resend_activation", via: %i[get post]
  match "users/reset_password(/:id)(.:format)", to: "users#reset_password", via: %i[get post]
  match "users/show(/:id)(.:format)", to: "users#show", via: %i[get post]
  match "users/signups(/:id)(.:format)", to: "users#signups", via: %i[get post]
  match "users/stratml(/:id)(.:format)", to: "users#stratml", via: %i[get post]
  match "users/suspend(/:id)(.:format)", to: "users#suspend", via: %i[get post]
  match "users/unfollow(/:id)(.:format)", to: "users#unfollow", via: %i[get post]
  match "users/unsuspend(/:id)(.:format)", to: "users#unsuspend", via: %i[get post]
  match "users/update(/:id)(.:format)", to: "users#update", via: %i[get post]
  match "videos/index(/:id)(.:format)", to: "videos#index", via: %i[get post]
  match "vote/index(/:id)(.:format)", to: "vote#index", via: %i[get post]
  match "vote/maybe(/:id)(.:format)", to: "vote#maybe", via: %i[get post]
  match "vote/no(/:id)(.:format)", to: "vote#no", via: %i[get post]
  match "vote/yes(/:id)(.:format)", to: "vote#yes", via: %i[get post]
  match "votes/create(/:id)(.:format)", to: "votes#create", via: %i[get post]
  match "votes/destroy(/:id)(.:format)", to: "votes#destroy", via: %i[get post]
  match "votes/edit(/:id)(.:format)", to: "votes#edit", via: %i[get post]
  match "votes/get_priority(/:id)(.:format)", to: "votes#get_priority", via: %i[get post]
  match "votes/index(/:id)(.:format)", to: "votes#index", via: %i[get post]
  match "votes/new(/:id)(.:format)", to: "votes#new", via: %i[get post]
  match "votes/show(/:id)(.:format)", to: "votes#show", via: %i[get post]
  match "votes/update(/:id)(.:format)", to: "votes#update", via: %i[get post]
  match "widgets/discussions(/:id)(.:format)", to: "widgets#discussions", via: %i[get post]
  match "widgets/index(/:id)(.:format)", to: "widgets#index", via: %i[get post]
  match "widgets/points(/:id)(.:format)", to: "widgets#points", via: %i[get post]
  match "widgets/preview(/:id)(.:format)", to: "widgets#preview", via: %i[get post]
  match "widgets/preview_iframe(/:id)(.:format)", to: "widgets#preview_iframe", via: %i[get post]
  match "widgets/priorities(/:id)(.:format)", to: "widgets#priorities", via: %i[get post]

  # Bare controller paths (-> index), which the catch-all served with its
  # default action.
  match "about(/:id)(.:format)", to: "about#index", via: %i[get post]
  match "activities(/:id)(.:format)", to: "activities#index", via: %i[get post]
  match "ads(/:id)(.:format)", to: "ads#index", via: %i[get post]
  match "blurbs(/:id)(.:format)", to: "blurbs#index", via: %i[get post]
  match "branch_users(/:id)(.:format)", to: "branch_users#index", via: %i[get post]
  match "branches(/:id)(.:format)", to: "branches#index", via: %i[get post]
  match "briefing(/:id)(.:format)", to: "briefing#index", via: %i[get post]
  match "changes(/:id)(.:format)", to: "changes#index", via: %i[get post]
  match "color_schemes(/:id)(.:format)", to: "color_schemes#index", via: %i[get post]
  match "comments(/:id)(.:format)", to: "comments#index", via: %i[get post]
  match "constituents(/:id)(.:format)", to: "constituents#index", via: %i[get post]
  match "delayed_jobs(/:id)(.:format)", to: "delayed_jobs#index", via: %i[get post]
  match "document_revisions(/:id)(.:format)", to: "document_revisions#index", via: %i[get post]
  match "documents(/:id)(.:format)", to: "documents#index", via: %i[get post]
  match "email_templates(/:id)(.:format)", to: "email_templates#index", via: %i[get post]
  match "endorsements(/:id)(.:format)", to: "endorsements#index", via: %i[get post]
  match "following_discussions(/:id)(.:format)", to: "following_discussions#index", via: %i[get post]
  match "followings(/:id)(.:format)", to: "followings#index", via: %i[get post]
  match "inbox(/:id)(.:format)", to: "inbox#index", via: %i[get post]
  match "install(/:id)(.:format)", to: "install#index", via: %i[get post]
  match "issues(/:id)(.:format)", to: "issues#index", via: %i[get post]
  match "legislators(/:id)(.:format)", to: "legislators#index", via: %i[get post]
  match "messages(/:id)(.:format)", to: "messages#index", via: %i[get post]
  match "network(/:id)(.:format)", to: "network#index", via: %i[get post]
  match "news(/:id)(.:format)", to: "news#index", via: %i[get post]
  match "pages(/:id)(.:format)", to: "pages#index", via: %i[get post]
  match "partners(/:id)(.:format)", to: "partners#index", via: %i[get post]
  match "points(/:id)(.:format)", to: "points#index", via: %i[get post]
  match "priorities(/:id)(.:format)", to: "priorities#index", via: %i[get post]
  match "prioritizer(/:id)(.:format)", to: "prioritizer#index", via: %i[get post]
  match "revisions(/:id)(.:format)", to: "revisions#index", via: %i[get post]
  match "searches(/:id)(.:format)", to: "searches#index", via: %i[get post]
  match "settings(/:id)(.:format)", to: "settings#index", via: %i[get post]
  match "signups(/:id)(.:format)", to: "signups#index", via: %i[get post]
  match "splash(/:id)(.:format)", to: "splash#index", via: %i[get post]
  match "tags(/:id)(.:format)", to: "tags#index", via: %i[get post]
  match "user_contacts(/:id)(.:format)", to: "user_contacts#index", via: %i[get post]
  match "users(/:id)(.:format)", to: "users#index", via: %i[get post]
  match "videos(/:id)(.:format)", to: "videos#index", via: %i[get post]
  match "vote(/:id)(.:format)", to: "vote#index", via: %i[get post]
  match "votes(/:id)(.:format)", to: "votes#index", via: %i[get post]
  match "widgets(/:id)(.:format)", to: "widgets#index", via: %i[get post]
end