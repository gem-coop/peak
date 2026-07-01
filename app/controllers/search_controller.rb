class SearchController < ApplicationController
  http_basic_authenticate_with(**Peak.admin.http_basic)

  def index
    @query = params[:q].presence
    @namespaces = Namespace.named_like(@query).limit(10).load_async
    @search_indexes = Namespace::Gem::SearchIndex.includes(gem: :namespace).search(@query).limit(20).load_async
  end
end
