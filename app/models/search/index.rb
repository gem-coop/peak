class Search::Index < ApplicationRecord
  belongs_to :namespace
  belongs_to :record, polymorphic: true

  def self.search(query)
    includes(:namespace, :record).order(:record_type, "length(content) DESC").where("to_tsvector('english', content) @@ to_tsquery('english', ? || ':*')", query)
  end

  def self.reindex(**options)
    upsert(options, update_only: :content, unique_by: :index_search_indexes_on_record)
  end

  def gem
    record if record.is_a?(Namespace::Gem)
  end

  def result_name
    gem&.namespaced_name || record.name
  end

  def stripped
    gem ? content.byteslice(gem.namespaced_name.size..) : content
  end
end
