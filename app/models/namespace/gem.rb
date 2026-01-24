class Namespace::Gem < ApplicationRecord
  belongs_to :namespace
  has_many :versions do
    def trimmed
      gem = proxy_association.owner
      gem.trim_versions_published_at&.then { published_since _1 } || self
    end
  end

  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name

  def to_param = name

  def self.version_from(name:, ref:)
    find_or_create_by!(name:).versions.find_or_initialize_by(ref:)
  end
end
