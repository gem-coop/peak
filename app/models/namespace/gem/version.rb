class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  belongs_to :index, class_name: "Namespace::Index"
  belongs_to :created_by, class_name: "User"
  belongs_to :platform, class_name: "Peak::Platform"

  has_many :linkings, dependent: :destroy
  has_many :links, through: :linkings

  has_many :nodes, dependent: :destroy
  has_many :references, through: :nodes do
    def line = parts.join(",")

    def parts
      group_by(&:name).map do |name, refs|
        "#{name}:#{refs.map(&:part).join("&")}"
      end
    end
  end
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  has_object :metadata
  has_one_attached :package

  scope :published_before, -> { where(published_at: .._1) }
  scope :published_after, -> { where(published_at: _1..) }
  scope :latest_first, -> { order(published_at: :desc, ref: :desc) }
  scope :latest_last, -> { order(published_at: :asc, ref: :asc) }
  def self.latest = latest_last.last

  def versions_upto_self = index.versions.where(slice(:gem_id)).upto(self)
  scope :upto, -> { published_before(_1.published_at) }

  scope :for,    -> { joins(:gem).where(gem: {name: _1}) }
  scope :system, -> { where(created_by: Peak.system_user) }
  scope :distinct_on_gem_name, -> { includes(:gem).distinct_on("namespace_gems.name").merge(Namespace::Gem.alphabetized) }
  def self.latest_for(name) = self.for(name).latest

  scope :as_byline, -> { select(:id, :ref, :summary, :published_at, :index_id, :gem_id, :created_by_id).includes(:gem, :created_by) }
  scope :missing_precompiles, -> { has_extensions.joins(:platform).merge(Peak::Platform.precompile_targeted) }
  scope :has_extensions, -> { where(has_extensions: true) }
  scope :pure, -> { joins(:platform).merge(Peak::Platform.pure) }

  def self.checksum = Digest::MD5.hexdigest(lines)
  def self.lines = latest_last.pluck(:line).join
  def self.refs = latest_last.pluck(:ref)

  def self.envelopes
    ordering = "namespace_gem_versions.published_at, namespace_gem_versions.ref"
    refs  = "string_agg(namespace_gem_versions.ref, ',' ORDER BY #{ordering})"
    lines = "string_agg(namespace_gem_versions.line, '' ORDER BY #{ordering})"

    joins(:gem)
      .group("namespace_gems.name")
      .order("namespace_gems.name")
      .pluck(Arel.sql("concat_ws(' ', namespace_gems.name, #{refs}, md5(#{lines}))"))
      .join("\n") << "\n"
  end

  def to_param = filename
  def filename = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"
  alias_method :package_name, :filename

  attribute :published_at, default: -> { Time.current }

  def process(...)
    consume(...)
    gem.version_uploaded self
    index.version_uploaded self
  end

  def consume(upload, **)
    self.package = { io: upload.tmpfile, filename: } if upload.tmpfile
    self.link_ids = links.unscoped.ids_from(upload.links)
    self.reference_ids = references.unscoped.ids_from(upload.requirement_triples)

    assign(**upload.slice(:platform_id, :has_extensions, :summary, *metadata.keys).compact_blank, **)
    update! line: compute_line
  end

  def envelope(ref_stamp: nil)
    versions_upto_self => versions
    "#{gem.name} #{ref_stamp || versions.refs.join(",")} #{versions.checksum}\n"
  end

  def compute_line
    "#{ref} #{references.line}#{metadata.line}\n"
  end
end
