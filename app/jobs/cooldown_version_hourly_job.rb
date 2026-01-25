class CooldownVersionHourlyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    CooldownVersionBackfillPublishedAtJob.perform_now

    CooldownVersionImportJob.perform_later

    CooldownVersionHourlyJob.set(wait: 1.hour).perform_later
  end
end
