Rails.application.routes.draw do
  mount_avo

  require "sidekiq/web"
  require "sidekiq-scheduler/web"
  Sidekiq::Web.use(Rack::Auth::Basic) do |u, p|
    Peak.admin.authenticate(u, p)
  end unless Rails.env.local?
  mount Sidekiq::Web => "/sidekiq"

  namespace "user/keys", as: :user_keys do
    resources :sessions, only: %i[new create]
  end

  scope module: :namespaces, defaults: { namespace: "@public" }, as: :public do
    get "/cooldown/versions" => "cooldown#versions"
    get "/cooldown/info/:name" => "cooldown#info"
    get "/cooldown/gems/:gem" => "cooldown#gems", constraints: {gem: Peak::Gem.pattern}

    get "/versions" => "mirror#versions"
    get "/info/:name" => "mirror#info"
    get "/gems/:gem" => "mirror#gems", constraints: {gem: Peak::Gem.pattern}
    post "/api/v1/gems", to: "gems#create", as: :gem_push
  end

  constraints -> { _1.params[:namespace].then { it.starts_with?("@") && it != "@public" } } do
    namespace :namespaces, path: "/:namespace/", as: :namespace do
      get :versions,   to: "index#index", as: :versions
      get "/info/:id", to: "index#show", as: :info

      get "/gems/:id", to: "gems#show", as: :gems, constraints: {id: Peak::Gem.pattern}
      post "/api/v1/gems", to: "gems#create", as: :gem_push

      root to: "profiles#show", as: :profile
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: redirect("https://gem.coop/cooldowns", status: :found)
end
