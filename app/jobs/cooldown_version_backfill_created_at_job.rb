class CooldownVersionBackfillCreatedAtJob < ApplicationJob
  queue_as :default

  def perform(*args)
    CooldownVersion.backfill_published_at
  end
end
