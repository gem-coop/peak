class User::Session < ApplicationRecord
  belongs_to :user
  attribute :resumed_at, default: -> { Time.current }

  def self.latest_id
    order(created_at: :desc).pick(:id)
  end

  def resumed
    touch :resumed_at
    self
  end
end
