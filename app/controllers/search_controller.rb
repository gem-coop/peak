class SearchController < ApplicationController
  rate_limit to: 40, within: 30.seconds, with: :rate_limit_response

  def index
    @query = params[:q].presence
    @namespaces = Namespace.named_like(@query).limit(10).load_async
    @search_indexes = Namespace::Gem::SearchIndex.includes(gem: :namespace).search(@query).limit(20).load_async
  end

  private
    def rate_limit_response
      render Peak::Error("You can only search 40 times every 30 seconds. Try again later."), status: :too_many_requests
    end
end
