class Namespace::Index < ApplicationRecord
  belongs_to :namespace
  default_scope { select(*column_names.without("versions_contents")) }

  has_many :gems
  has_many :infos,    through: :gems, class_name: "Namespace::Gem::Info"
  has_many :versions, through: :gems, class_name: "Namespace::Gem::Version"
  enum :access, %i[external internal].index_by(&:itself), suffix: true

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

  private
    def contents = infos.pluck(:envelope).join.prepend(frontmatter)
    def frontmatter = "---\n"
end
