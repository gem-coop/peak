class CooldownVersionHourlyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Import all the gems in versions we don't have
    CooldownVersionImportJob.perform_later
    # Do this again in an hour
    CooldownVersionHourlyJob.set(wait: 1.hour).perform_later
  end
end
