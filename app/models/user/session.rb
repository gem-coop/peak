class User::Session < ApplicationRecord
  belongs_to :user
  attribute :resumed_at, default: -> { Time.current }

  def resumed
    touch :resumed_at
    self
  end
end
