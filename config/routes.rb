Rails.application.routes.draw do
  mount_avo if Peak.avo?

  require "sidekiq/web"
  require "sidekiq-scheduler/web"
  Sidekiq::Web.use(Rack::Auth::Basic) do |u, p|
    Peak.admin.authenticate(u, p)
  end unless Rails.env.local?
  mount Sidekiq::Web => "/sidekiq"

  namespace :user do
    resources :email_verifications, only: %i[new create show]
    resources :push_keys, only: %i[new create]
    resources :sessions, only: %i[show]
  end

  get "/sign_up" => "user/sign_ups#new", as: :user_sign_ups
  post "/sign_up" => "user/sign_ups#create"

  get "/sign_in" => "user/sign_ins#new", as: :sign_in
  post "/sign_in" => "user/sign_ins#create"
  delete "/sign_out" => "user/sessions#destroy", as: :sign_out

  get "/dashboard" => "dashboard#show", as: :dashboard

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
    namespace :namespaces, path: "/:namespace(/:index)", as: :namespace do
      get :versions,   to: "index#index", as: :versions
      get "/info/:id", to: "index#show", as: :info

      get "/gems/:id", to: "gems#show", as: :gems, constraints: {id: Peak::Gem.pattern}
      post "/api/v1/gems", to: "gems#create", as: :gem_push
      get "/:id", to: "gems/profiles#show", as: :gem
    end

    get "/:namespace", to: "namespaces/profiles#show", as: :namespace
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: "user/sign_ups#new"
end
