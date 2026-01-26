class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem

  has_many :nodes
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :published_since, -> { where(published_at: _1..).published_order }
  scope :published_order, -> { order(:published_at) }

  scope :for, -> { joins(:gem).where(gem: {name: _1}) }

  has_one_attached :package
  after_create :version_uploaded

  attribute :published_at, default: -> { Time.current }

  def to_param = filename
  def filename = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"
  alias_method :package_name, :filename

  def process(upload)
    update! checksum: upload.checksum, package: { io: upload.tmpfile, filename: }
  end


  def line
    "#{ref} #{references.line}#{line_formatted_metadata}\n"
  end

  def metadata
    {checksum:, ruby:, rubygems:, published_at:}.compact_blank
  end

  private
    def version_uploaded = gem.version_uploaded(self)

    def line_formatted_metadata
      metadata.as_json.map { "#{_1}:#{_2}" }.join(",").presence&.then { "|#{_1}" }
    end
end
