class ClearExpiredPushKeysJob < ApplicationJob
  queue_as :default

  def perform
    User::PushKey.expired.destroy_later_bulk
  end
end
