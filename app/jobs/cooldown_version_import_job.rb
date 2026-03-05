class CooldownVersionImportJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Import queue of #{import_queue_size} is not empty, skipping new import."
    return if import_queue_size > 0

    count = CooldownVersion.import
    Rails.logger.info "Finished importing, and queued #{count} jobs"
    nil
  end

  def import_queue_size
    @import_queue_size ||= Sidekiq::Stats.new.queues.slice(*CooldownVersion::IMPORT_QUEUES).values.sum
  end
end
