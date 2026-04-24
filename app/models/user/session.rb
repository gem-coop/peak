class User::Session < ApplicationRecord
  belongs_to :user
  attribute :resumed_at, default: -> { Time.current }

  def resumed
    touch :resumed_at
    self
  end
end

# == Schema Information
#
# Table name: user_sessions
#
#  id         :bigint           not null, primary key
#  ip_address :string           not null
#  resumed_at :datetime         not null
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_sessions_on_user_id  (user_id)
#
