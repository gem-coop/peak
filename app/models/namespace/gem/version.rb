class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  belongs_to :created_by, class_name: "User"

  has_many :nodes
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :published_since, -> { where(published_at: _1..).published_order }
  scope :published_order, -> { order(:published_at) }

  scope :for, -> { joins(:gem).where(gem: {name: _1}) }
  scope :system, -> { where(created_by: Peak.system_user) }

  def to_param = filename
  def filename = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"
  alias_method :package_name, :filename

  has_one_attached :package
  after_create :version_uploaded

  has_object :metadata
  attribute :published_at, default: -> { Time.current }

  def process(upload, **)
    self.reference_ids = references.unscoped.ids_from(upload.requirement_triples)
    update! **metadata.extract_from(upload), package: { io: upload.tmpfile, filename: }, **
  end

  def line
    "#{ref} #{references.line}#{metadata.line}\n"
  end

  private
    def version_uploaded = gem.version_uploaded(self)
end
