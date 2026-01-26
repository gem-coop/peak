class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem

  has_many :nodes
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :published_since, -> { where(published_at: _1..).published_order }
  scope :published_order, -> { order(:published_at) }

  scope :for, -> { joins(:gem).where(gem: {name: _1}) }

  has_one_attached :package

  attribute :published_at, default: -> { Time.current }

  def to_param = filename
  def filename = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"
  alias_method :package_name, :filename

  def line
    "#{ref} #{references.line}#{line_formatted_metadata}\n"
  end

  def metadata
  end

  def finish_upload!(upload)
    update! checksum: upload.checksum, package: { io: upload.tmpfile, filename: }
    gem.version_uploaded(self)
    {checksum:, ruby:, rubygems:, published_at:}.compact_blank
  end

  private
    def line_formatted_metadata
      metadata.as_json.map { "#{_1}:#{_2}" }.join(",").presence&.then { "|#{_1}" }
    end
end
