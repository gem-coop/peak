class Namespace::Index < ApplicationRecord
  belongs_to :namespace
  has_many :cooldowns, dependent: :destroy
  attribute :last_compacted_at, default: -> { Time.current }

  concerning :Manifested do
    included do
      has_one_built :manifest, as: :author
      delegate :compact, :compact_later, :append, :append_later, :contents, to: :manifest
    end
  end

  has_many :gems, -> { alphabetized }, dependent: :destroy
  has_many :versions, through: :gems, class_name: "Namespace::Gem::Version"

  enum :access, %i[public private].index_by(&:itself), suffix: true

  validates_presence_of :slug
  normalizes :slug, with: -> { _1.to_s.parameterize }
  before_destroy { throw :abort if slug.inquiry.default? } # Can't destroy default index.

  def self.locate_or_default(slug)
    find_by!(slug: slug.presence || :default)
  end
end
