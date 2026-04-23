class Namespace::Gem < ApplicationRecord
  belongs_to :index
  belongs_to :namespace, default: -> { index.namespace }

  has_one :info, dependent: :destroy
  has_many :cooldown_infos, dependent: :destroy
  before_create :build_info
  after_create :create_cooldown_infos

  has_object :imports, :server

  def self.named(name) = find_by!(name:)
  def to_param = name

  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name
  has_many :versions, dependent: :destroy do
    def trimmed
      gem = proxy_association.owner
      gem.trim_versions_published_at&.then { published_since _1 } || self
    end
  end
  has_many :platforms, -> { distinct }, through: :versions

  def self.version_from(name:, ref:)
    find_or_create_by!(name:).versions.find_or_initialize_by(ref:)
  end

  performs def process_version(version)
    index.append info.rebuild.envelope_from(version.ref)
  end
  def version_uploaded(version) = process_version_later(version)

private

  def create_cooldown_infos
    index.cooldowns.find_each do |cooldown|
      cooldown_infos.find_or_create_by!(cooldown:)
    end
  end
end
