class Namespace::Index::Cooldown < ApplicationRecord
  include Namespace::Index::Manifested

  belongs_to :index
  has_many :gems, through: :index
  has_many :versions, -> { published_before _1.published_threshold }, through: :index do
    def refreshed = published_after(proxy_association.owner.refreshed_at)
  end

  scope :refresh_due, -> { where(refresh_due_at: Time.current..).where("refresh_due_at <= refreshed_at") }
  attribute :refresh_due_at, default: -> { Time.current }

  performs def refresh
    if refreshed = versions.refreshed.includes(:gem).presence
      manifest.append refreshed
      touch :refreshed_at
    end
  end

  def published_threshold
    interval.ago
  end

  def project_version_incoming(at:)
    timestamp = interval.since(at)
    p(at:, timestamp:, refresh_due_at:)

    update! refresh_due_at: timestamp if timestamp.before?(refresh_due_at)
  end
end
