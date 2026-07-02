class Namespace::Gem::SearchIndex < ApplicationRecord
  belongs_to :gem

  scope :search, -> { order("length(content) DESC")
    .where("to_tsvector('english', content) @@ to_tsquery('english', ? || ':*')", _1) if _1.present? }

  def self.reindex(**options)
    upsert(options, update_only: :content, unique_by: :gem_id)
  end

  def stripped
    content.byteslice(gem.name.size..)
  end
end
