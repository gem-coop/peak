class Namespace::Gem::Version::Link < ApplicationRecord
  has_many :linkings, dependent: :destroy
  has_many :versions, through: :linkings

  def self.ids_from(links)
    upsert_all links.map { {key: _1, value: _2} }
  end

  def self.upsert_all(values)
    # Also collect already inserted ids with `update_only:`.
    super(values, update_only: :value, returning: :id,
      unique_by: :namespace_gem_version_links_uniqueness).rows.flat_map(&:first)
  end
end
