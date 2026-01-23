class CooldownVersionBackfillCreatedAtJob < ApplicationJob
  queue_as :default

  def perform(*args)
    CooldownVersion.backfill_created_at
  end
end
