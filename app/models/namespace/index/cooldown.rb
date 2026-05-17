class Namespace::Index::Cooldown < ApplicationRecord
  include Namespace::Index::Manifested

  belongs_to :index
  has_many :gems, through: :index
  has_many :versions, -> { published_before _1.interval.ago }, through: :index

  scope :refresh_due, -> { joins(:projections).merge(Projection.due) }

  has_many :projections, dependent: :destroy
  delegate :project, :realign, to: :projections
  after_save_commit :realign, if: :interval_previously_changed?

  performs def refresh
    if versions = projections.due.extract_associated(:version)
      manifest.append versions
      projections.due.delete_all
    end
  end
end
