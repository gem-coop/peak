module Search::Indexed extend ActiveSupport::Concern
  included do
    has_one_built :search_index, as: :record, class_name: "Search::Index", dependent: :delete

    after_save :reindex_later
    performs :reindex
  end

  def reindex
    namespace = try(:namespace) || self
    Search::Index.where(record: self, namespace:).reindex(content: indexing_content)
  end
end
