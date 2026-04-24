class Peak::Terms < ApplicationRecord
  declare_immutable if: :finalized?

  enum :status, %i[drafted finalized].index_by(&:itself)

  has_many :acceptances
  has_many :users, through: :acceptances

  # Reuse previous latest terms as the base content if we create new terms.
  attribute :content, default: -> { latest&.content }

  def self.latest
    finalized.order(created_at: :desc).first
  end
  singleton_class.delegate :acceptance_for, to: :latest, allow_nil: true

  def acceptance_for(user)
    acceptances.find_or_initialize_by(user:)
  end
end

# == Schema Information
#
# Table name: peak_terms
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  status     :string           default("drafted"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
