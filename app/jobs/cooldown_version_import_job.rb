class CooldownVersionImportJob < ApplicationJob
  queue_as :default

  def perform
    jobs_queued = CooldownVersion.import
    Rails.logger.info "Finished importing, and queued #{jobs_queued.size} jobs"
    nil
  end
end
