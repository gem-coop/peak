class CooldownVersionImportJob < ApplicationJob
  queue_as :default

  def perform
    count = CooldownVersion.import
    Rails.logger.info "Finished importing, and queued #{count} jobs"
    nil
  end
end
