class Namespace::Index < ApplicationRecord
  belongs_to :namespace
  default_scope { select(*column_names.without("versions_contents")) }

  has_many :gems,     dependent: :destroy
  has_many :infos,    through: :gems, class_name: "Namespace::Gem::Info"
  has_many :versions, through: :gems, class_name: "Namespace::Gem::Version"
  has_many :cooldowns, dependent: :destroy
  enum :access, %i[external dev private].index_by(&:itself), suffix: true

  attribute :last_compacted_at, default: -> { Time.current }

  def self.locate_or_external(access)
    find_by!(access: access&.presence_in(accesses.keys) || :external)
  end

  def cooldown(days:)
    cooldowns.find_or_create_by!(days_delayed: days)
  end

  def append(envelope)
    versions_contents << envelope
    save!
  end

  def versions_contents
    read_unloaded_attribute __method__
  end

  performs def compact
    update! versions_contents: contents, last_compacted_at: Time.current
  end

  def public_cache?
    external_access? || dev_access?
  end

  private
    def contents = infos.pluck(:envelope).join.prepend(frontmatter)
    def frontmatter = "created_at: #{Time.now.utc.iso8601}\n---\n"
end
