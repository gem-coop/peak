class Namespace::Index::Cooldown::Refresh::FanoutJob < ApplicationJob
  def perform
    Namespace::Index::Cooldown.refresh_due.refresh_later_bulk
  end
end
