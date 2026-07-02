class SearchController < ApplicationController
  require_peak_admin_authentication

  def index
    @query = params[:q].presence
    @namespaces = Namespace.named_like(@query).limit(10).load_async
    @search_indexes = Namespace::Gem::SearchIndex.includes(gem: :namespace).search(@query).limit(20).load_async
  end
end
