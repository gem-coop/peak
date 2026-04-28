class Namespace::Index::Cooldown < ApplicationRecord
  include Namespace::Index::Manifested

  belongs_to :index
  has_many :gems, through: :index
  has_many :versions, -> { published_before _1.published_threshold }, through: :index

  after_create :compact_later

  performs def refresh
    if versions = new_versions_since_last_refresh.includes(:gem).presence
      manifest.append versions
      touch
    end
  end

  def new_versions_since_last_refresh
    versions.published_after updated_at
  end

  def published_threshold
    interval.ago
  end
end
