class Namespace::Gem < ApplicationRecord
  include SearchIndex::Indexed

  belongs_to :namespace

  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name
  has_many :versions, dependent: :destroy
  has_many :platforms, -> { distinct }, through: :versions

  has_object :imports, :server

  scope :alphabetized, -> { order(name: :asc) }

  # Namespace::Gem.locate("oaken") # => @rubygems/oaken
  # Namespace::Gem.locate("@kaspth/oaken") # => @kaspth/oaken
  def self.locate(name)
    *gunk, gem, namespace = name.split("/").reverse
    raise ArgumentError, "too many segments in name" unless gunk.empty?
    Namespace.named(namespace || :@rubygems).gems.named(gem)
  end

  def self.named(name) = find_by!(name:)
  def to_param = name

  def version_uploaded(version) = reindex_later

  def namespaced_name
    "#{namespace.name}/#{name}"
  end

  # Ref: https://github.com/package-url/purl-spec
  def to_purl
    "pkg:gem/gem.coop/#{namespaced_name.delete_prefix("@")}"
  end
end
