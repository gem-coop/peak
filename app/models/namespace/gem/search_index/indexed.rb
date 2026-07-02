Namespace::Gem::SearchIndex.concern :Indexed do
  included do
    has_one_built :search_index, dependent: :delete

    performs :reindex
    after_save :reindex_later
  end

  def reindex
    search_index_scope.reindex(content: indexing_content)
  end

  def indexing_content
    "#{name} #{versions.latest_first.pick(:summary)}"
  end
end
