Sidekiq.configure_server do |config|
  config.on(:startup) do
    ActiveRecord::Base.clear_active_connections!
  end
end
