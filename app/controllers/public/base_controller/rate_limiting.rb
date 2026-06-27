# TODO: Bother submitting to Rails?
module Public::BaseController::RateLimiting
  def rate_limiting(by:, name: nil, scope: controller_path, store: cache_store)
    Limit.new(store:, by:, scope:, name:)
  end

  Limit = Data.define(:store, :by, :scope, :name) do
    def read
      store.read key
    end

    def increment(by: 1)
      store.increment key, by
    end

    def decrement(by: 1)
      store.decrement key, by
    end

    def key
      ["rate-limit", scope, name, by].compact.join(":")
    end
  end
end
