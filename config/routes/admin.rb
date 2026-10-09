require "sidekiq/web"
require "sidekiq-scheduler/web"

scope :admin do
  if Rails.env.local?
    mount Sidekiq::Web => "/sidekiq"
    mount_avo at: "/" if Peak.avo?
  else
    get "/callback/github" => "admin/sessions#create"
    get "/logout" => "admin/sessions#destroy"

    # see initializers/warden_github.rb for config
    constraints -> { Peak.admin.authenticate _1 } do
      mount Sidekiq::Web => "/sidekiq"
      mount_avo at: "/" if Peak.avo?
    end
  end
end
