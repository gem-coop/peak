class Namespace::Index < ApplicationRecord
  belongs_to :namespace
  has_remote_text_blob :versions_blob, optional: true

  has_many :gems
  has_many :infos,    through: :gems, class_name: "Namespace::Gem::Info"
  has_many :versions, through: :gems, class_name: "Namespace::Gem::Version"
  enum :access, %i[external internal].index_by(&:itself), suffix: true

  attribute :last_compacted_at, default: -> { Time.current }

  def append(envelope)
    compact unless versions_blob
    versions_blob.write envelope
  end

  performs def compact
    update! versions_blob: contents, last_compacted_at: Time.current
  end

  private
    def contents = infos.pluck(:envelope).join.prepend(frontmatter)
    def frontmatter = "---\n"
end
