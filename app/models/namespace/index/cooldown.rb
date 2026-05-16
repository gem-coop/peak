class Namespace::Index::Cooldown < ApplicationRecord
  include Namespace::Index::Manifested
  after_create :compact_later

  belongs_to :index
  has_many :gems, through: :index
  has_many :versions, -> { published_before _1.published_threshold }, through: :index do
    def refreshed = published_after(proxy_association.owner.refreshed_at)
  end

  performs def refresh
    if refreshed = versions.refreshed.includes(:gem).presence
      manifest.append refreshed
      touch :refreshed_at
    end
  end

  def published_threshold
    interval.ago
  end
end
