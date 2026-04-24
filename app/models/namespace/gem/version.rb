class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  belongs_to :created_by, class_name: "User"

  has_many :linkings, dependent: :destroy
  has_many :links, through: :linkings

  has_many :nodes, dependent: :destroy
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :published_since, -> { where(published_at: _1..).published_order }
  scope :published_order, -> { order(published_at: :desc, ref: :desc) }

  scope :for, -> { joins(:gem).where(gem: {name: _1}) }
  scope :system, -> { where(created_by: Peak.system_user) }

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

  def process(...)
    consume(...)
    gem.version_uploaded self
  end

  def consume(upload, **)
    self.platform_id = Peak::Platform.ids_from(upload.platform_key).first
    self.link_ids = links.unscoped.ids_from(upload.links)
    self.reference_ids = references.unscoped.ids_from(upload.requirement_triples)
    self.has_extensions = upload.has_extensions?
    self.summary = upload.summary.to_s
    self.package = { io: upload.tmpfile, filename: }
    update!(**metadata.extract_from(upload), **)
  end

  def line
    "#{ref} #{references.line}#{metadata.line}\n"
  end

  def trigger_precompile
    if has_extensions.nil?
      upload = Peak::Gem::Upload.read gem.server.download(ref)
      update!(has_extensions: upload.has_extensions?)
    end
    return unless has_extensions

    HTTPX.
      accept("application/vnd.github+json").
      with(headers: {
        "X-GitHub-Api-Version" => "2026-03-10",
        "Authorization" => "Bearer #{ENV.fetch("GITHUB_TOKEN")}"
      }).post(
        "https://api.github.com/repos/gem-coop/precompiled-gems/actions/workflows/263494733/dispatches",
        json: {ref: "main", inputs: {gem: name}}
      ) if ENV.key?("GITHUB_TOKEN")
  end
  performs :trigger_precompile
end

# == Schema Information
#
# Table name: namespace_gem_versions
#
#  id             :bigint           not null, primary key
#  checksum       :string
#  executables    :json             not null
#  has_extensions :boolean
#  licenses       :json             not null
#  published_at   :datetime         not null
#  ref            :string           not null
#  ruby           :string
#  rubygems       :string
#  summary        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  created_by_id  :bigint           not null
#  gem_id         :bigint           not null
#  platform_id    :bigint           not null
#
# Indexes
#
#  index_namepace_gem_versions_uniqueness         (gem_id,ref) UNIQUE
#  index_namespace_gem_versions_on_created_by_id  (created_by_id)
#  index_namespace_gem_versions_on_gem_id         (gem_id)
#  index_namespace_gem_versions_on_platform_id    (platform_id)
#
