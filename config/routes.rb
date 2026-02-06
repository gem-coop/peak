Rails.application.routes.draw do
  mount_avo if Rails.env.development?
  mount MissionControl::Jobs::Engine, at: "/jobs"

  namespace "user/keys", as: :user_keys do
    resources :sessions, only: %i[new create]
  end

  concern :gem_routing do
    get :versions,   to: "index#index", as: :versions
    get "/info/:id", to: "index#show", as: :info

    get "/gems/:id", to: "gems#show", as: :gems, constraints: {id: Peak::Gem.pattern}
    post "/api/v1/gems", to: "gems#create", as: :gem_push
  end

  scope module: :namespaces, defaults: { namespace: "@public" } do
    get "/cooldown/versions" => "cooldown#versions"
    get "/cooldown/info/:name" => "cooldown#info"
    get "/cooldown/gems/:gem" => "cooldown#gems", constraints: {gem: Peak::Gem.pattern}

    get "/versions" => "mirror#versions"
    get "/info/:name" => "mirror#info"
    get "/gems/:gem" => "mirror#gems", constraints: {gem: Peak::Gem.pattern}
    post "/api/v1/gems", to: "gems#create", as: :gem_push
  end

  namespace :namespaces, path: "/:namespace/" do
    concerns :gem_routing
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
