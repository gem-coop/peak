class Namespace::Gem::SearchIndex < ApplicationRecord
  belongs_to :gem

  scope :search, -> do
    _1.blank? ? none : order("length(content) DESC").where(<<~SQL, _1)
      to_tsvector('english', content) @@
        replace(websearch_to_tsquery('english', ?)::text || ' ', ''' ', ''':*')::tsquery
    SQL
  end

  def self.reindex(**options)
    upsert(options, update_only: :content, unique_by: :gem_id)
  end

  def stripped
    content.byteslice(gem.name.size..)
  end
end
