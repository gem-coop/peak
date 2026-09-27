class Namespace::Mirror::SyncFanoutJob < ApplicationJob
  queue_as :default

  def perform
    Namespace::Mirror.enabled.sync_later_bulk
  end
end
