class Namespace::Index < ApplicationRecord
  belongs_to :namespace
  has_many :gems, through: :namespace
  has_many :versions, class_name: "Namespace::Gem::Version", dependent: :destroy

  has_many :cooldowns, dependent: :destroy

  concerning :Manifested do
    included do
      has_one_built :manifest, as: :author
      delegate :compact, :compact_later, :append, :append_later, :contents, to: :manifest
    end
  end

  enum :access, %i[public private].index_by(&:itself), suffix: true

  validates_presence_of :slug
  normalizes :slug, with: -> { _1.to_s.parameterize }
  before_destroy { throw :abort if default? } # Can't destroy default index.

  def self.locate_or_default(slug)
    find_by!(slug: slug.presence || :default)
  end

  def version_from(name:, ref:)
    versions.find_or_initialize_by(ref:, gem: gems.find_or_create_by!(name:))
  end

  performs def process_version(version)
    append version
    cooldowns.each { _1.project version }
  end
  def version_uploaded(version) = process_version_later(version)

  def default? = slug == "default"
end
