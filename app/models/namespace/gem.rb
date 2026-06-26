class Namespace::Gem < ApplicationRecord
  belongs_to :index
  belongs_to :namespace, default: -> { index.namespace }

  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name
  has_many :versions, dependent: :destroy
  has_many :platforms, -> { distinct }, through: :versions

  has_object :imports, :server

  scope :alphabetized, -> { order(name: :asc) }
  validates :name, format: { with: Peak::Gem.name_format }

  def self.named(name) = find_by!(name:)
  def to_param = name

  def self.version_from(name:, ref:)
    find_or_create_by!(name:).versions.find_or_initialize_by(ref:)
  end

  performs def process_version(version)
    index.process_version(version)
  end
  def version_uploaded(version) = process_version_later(version)
end
