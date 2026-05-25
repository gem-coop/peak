class Namespace::Gem < ApplicationRecord
  belongs_to :index
  belongs_to :namespace, default: -> { index.namespace }

  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name
  has_many :versions, dependent: :destroy
  has_many :platforms, -> { distinct }, through: :versions

  has_object :imports, :server

  scope :alphabetized, -> { order(name: :asc) }
  validates_format_of :name, with: Peak::Gem.name_pattern

  def self.named(name) = find_by!(name:)
  def to_param = name

  def self.version_from(name:, ref:)
    find_or_create_by!(name:).versions.find_or_initialize_by(ref:)
  end

  def version_uploaded(version)
    index.append_later version
  end
end
