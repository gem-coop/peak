class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  belongs_to :created_by, class_name: "User"

  has_many :linkings
  has_many :links, through: :linkings

  has_many :nodes
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :published_since, -> { where(published_at: _1..).published_order }
  scope :published_order, -> { order(published_at: :desc, ref: :desc) }

  scope :for, -> { joins(:gem).where(gem: {name: _1}) }
  scope :system, -> { where(created_by: Peak.system_user) }

  belongs_to :platform, class_name: "Peak::Platform"

  scope :missing_precompiles, -> { has_extensions.joins(:platform).merge(Peak::Platform.precompile_targeted) }
  scope :has_extensions, -> { where(has_extensions: true) }

  def to_param = filename
  def filename = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"
  alias_method :package_name, :filename

  has_object :metadata
  has_one_attached :package
  attribute :published_at, default: -> { Time.current }

  def process(...)
    consume(...)
    gem.version_uploaded self
  end

  def consume(upload, **)
    self.platform_id = Peak::Platform.ids_from([upload.platform_key]).first
    self.link_ids = links.unscoped.ids_from(upload.links)
    self.reference_ids = references.unscoped.ids_from(upload.requirement_triples)
    self.has_extensions = upload.has_extensions?
    self.package = { io: upload.tmpfile, filename: }
    update! **metadata.extract_from(upload), **
  end

  def line
    "#{ref} #{references.line}#{metadata.line}\n"
  end
end
