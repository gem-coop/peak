class Namespace::Index::Cooldown < ApplicationRecord
  belongs_to :index
  default_scope { select(*column_names.without("versions_contents")) }

  has_many :gems, through: :index
  has_many :infos,    through: :gems, class_name: "Namespace::Gem::Info"
  has_many :versions, through: :gems, class_name: "Namespace::Gem::Version"

  attribute :last_compacted_at, default: -> { Time.current }

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
    index.external_access? || index.dev_access?
  end
end
