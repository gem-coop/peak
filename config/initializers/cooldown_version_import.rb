Rails.application.config.after_initialize do
  in_prod = !ENV.key?("SECRET_KEY_BASE_DUMMY") && Rails.env.production?
  not_console = !Rails.const_defined?("Console")
  versions_loaded = CooldownVersion.count > 1_690_000

  if in_prod && not_console && versions_loaded
    Rails.logger.info "Setting up CooldownVersionHourlyJob"
    CooldownVersionHourlyJob.perform_later
  end
rescue => e
  # if the database doesn't exist or something, we can just log about it
  Rails.logger.error("#{e.class}: #{e.message}")
end
