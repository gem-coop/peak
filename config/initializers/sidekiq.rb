Sidekiq.configure_server do |config|
  config.on(:startup) do
    ActiveRecord::Base.connection_handler.clear_active_connections!
  end
end
