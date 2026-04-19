  class Namespace::Index::Mirror::Upstream < ActiveRecord::AssociatedObject
    class GemYankedError < RuntimeError; end

    cattr_reader :memory_store, default:
      ActiveSupport::Cache.lookup_store(:memory_store, compress: true, size: 256.megabytes)

    delegate :upstream_url, to: :mirror

    def cached_get(path, expires_in:, store: self.memory_store)
      url = File.join(upstream_url, path)

      store.fetch(path, expires_in:) do
        HTTPX.plugin(:brotli).get(url).tap do |res|
          if res.is_a?(HTTPX::ErrorResponse) || 405 <= res.status
            raise "Request to #{res.uri} failed, got: #{res.inspect}"
          elsif path.ends_with?(".json") && res.status == 404
            raise GemYankedError, path
          end
        end.to_s
      end
    end

    def versions
      cached_get("/versions", expires_in: 30.minutes)
    end

    def versions_until(byte)
      versions.byteslice(...byte)
    end

    def info(name)
      cached_get("/info/#{name}", expires_in: 30.minutes)
    end

    def info_until(name, byte)
      info(name).byteslice(...byte)
    end

    def versions_json(name)
      JSON.parse cached_get("/api/v1/versions/#{name}.json", expires_in: 30.minutes)
    rescue GemYankedError
      {}
    end
  end
