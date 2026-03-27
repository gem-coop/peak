class Namespace::Gem < ApplicationRecord
  belongs_to :index
  belongs_to :namespace, default: -> { index.namespace }

  has_one :info
  before_create :build_info

  has_object :imports, :server

  def self.named(name) = find_by!(name:)
  def to_param = name


  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name
  has_many :versions do
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
end
