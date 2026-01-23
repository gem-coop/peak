Rails.application.config.after_initialize do
  auto_import = !ENV.key?("SECRET_KEY_BASE_DUMMY") && Rails.env.production? && CooldownVersion.count > 1_690_000
  # CooldownVersionHourlyJob.perform_later if auto_import
end
