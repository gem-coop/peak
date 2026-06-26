class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  belongs_to :created_by, class_name: "User"

  # Hold ref to RubyGems' version grammar so a crafted archive can't smuggle whitespace or control
  # bytes into the `/versions` manifest.
  validates :ref, presence: true, format: { with: Gem::Version::ANCHORED_VERSION_PATTERN }

  has_many :linkings, dependent: :destroy
  has_many :links, through: :linkings

  has_many :nodes, dependent: :destroy
  has_many :references, through: :nodes do
    def line = parts.join(",")

    def parts
      group_by(&:name).map do |name, refs|
        "#{Peak::CompactIndex.safe(name)}:#{refs.map { Peak::CompactIndex.safe _1.part }.join("&")}"
      end
    end
  end
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :published_before, -> { where(published_at: .._1).latest_last }
  scope :published_after, -> { where(published_at: _1..).latest_last }
  scope :latest_first, -> { order(published_at: :desc, ref: :desc) }
  scope :latest_last, -> { order(published_at: :asc, ref: :asc) }
  def self.latest = latest_last.last

  def versions_upto_self = gem.versions.upto(self)
  scope :upto, -> { published_before(_1.published_at) }

  scope :for,    -> { joins(:gem).where(gem: {name: _1}) }
  scope :system, -> { where(created_by: Peak.system_user) }
  def self.latest_for(name) = self.for(name).latest

  scope :as_byline, -> { select(:ref, :summary, :published_at, :created_by_id).includes(:created_by) }

  belongs_to :platform, class_name: "Peak::Platform"

  scope :missing_precompiles, -> { has_extensions.joins(:platform).merge(Peak::Platform.precompile_targeted) }
  scope :has_extensions, -> { where(has_extensions: true) }
  scope :pure, -> { joins(:platform).merge(Peak::Platform.pure) }

  def to_param = filename
  def filename = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"
  alias_method :package_name, :filename

  has_object :metadata
  has_one_attached :package
  attribute :published_at, default: -> { Time.current }

  def self.checksum = Digest::MD5.hexdigest(lines)
  def self.lines = pluck(:line).join
  def self.refs = pluck(:ref)

  def process(...)
    consume(...)
    gem.version_uploaded self
  end

  def consume(upload, **)
    self.package = { io: upload.tmpfile, filename: }
    self.link_ids = links.unscoped.ids_from(upload.links)
    self.reference_ids = references.unscoped.ids_from(upload.requirement_triples)

    assign(**upload.slice(:platform_id, :has_extensions, :summary, *metadata.keys).compact_blank, **)
    update! line: compute_line
  end

  def envelope(ref_stamp: nil)
    # function = Arel.sql("concat_ws(' ', string_agg(ref::text, ','), md5(string_agg(line::text, '')))"))
    # "#{gem.name} #{versions_upto_self.pick(function)}\n"

    versions = versions_upto_self
    "#{Peak::CompactIndex.safe(gem.name)} #{ref_stamp || versions.refs.join(",")} #{versions.checksum}\n"
  end

  def compute_line
    "#{Peak::CompactIndex.safe(ref)} #{references.line}#{metadata.line}\n"
  end
end
