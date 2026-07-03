class Namespace::Gem < ApplicationRecord
  include SearchIndex::Indexed

  belongs_to :namespace
  self.ignored_columns = ["index_id"]

  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name
  has_many :versions, dependent: :destroy
  has_many :platforms, -> { distinct }, through: :versions

  has_object :imports, :server

  scope :alphabetized, -> { order(name: :asc) }

  def self.named(name) = find_by!(name:)
  def to_param = name

  def version_uploaded(version) = reindex_later

  def namespaced_name
    "#{namespace.name}/#{name}"
  end
end
