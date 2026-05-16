class Namespace::Index::Cooldown::Refresh::FanoutJob < ApplicationJob
  def perform
    Namespace::Index::Cooldown.where(refreshed_at: ..10.minutes.ago).refresh_later_bulk
  end
end
