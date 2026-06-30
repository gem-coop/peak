# Encapsulates a deferred append of a version to a cooldown. Once due it's appended to the cooldown's manifest.
class Namespace::Index::Cooldown::Projection < ApplicationRecord
  belongs_to :cooldown
  belongs_to :version, class_name: "Namespace::Gem::Version"

  scope :due, -> { where(append_at: ..Time.current) }

  def self.project(version)
    find_or_initialize_by(version:).tap(&:realign)
  end

  def self.realign
    includes(:cooldown, :version).find_each(&:realign)
  end

  def realign
    update! append_at: cooldown.interval.since(version.published_at)
  end
end
