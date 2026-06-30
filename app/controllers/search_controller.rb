class SearchController < ApplicationController
  http_basic_authenticate_with(**Peak.admin.http_basic)

  def index
    @query = params[:q].presence
    @listings = Search::Index.search(@query).limit(20).load_async
  end
end
