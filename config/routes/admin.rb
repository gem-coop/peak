require "sidekiq/web"
require "sidekiq-scheduler/web"

scope :admin do
  # see initializers/warden_github.rb for config
  constraint = -> { Peak.admin.authenticate _1 }
  constraint = -> { true } if Rails.env.development? # Comment out to check admin authentication locally

  constraints constraint do
    mount Sidekiq::Web => "/sidekiq"
    mount_avo at: "/" if Peak.avo?
  end

  get "/callback/github" => "admin/sessions#create"
  get "/logout" => "admin/sessions#destroy"
end
