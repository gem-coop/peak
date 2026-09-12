module Peak
  class DisposableEmailList
    URL = "https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/refs/heads/main/disposable_email_blocklist.conf"
    MAX_BYTES = 16.megabytes

    mattr_accessor :expected_size, default: 1_000..500_000
    mattr_accessor :max_change, default: 0.5

    InvalidListError = Class.new(StandardError)

    def self.sync(...) = new(...).sync

    def initialize(url: URL)
      @url = url
    end

    def sync
      block vetted(fetch)
    end

    private
      mattr_reader :client, default: HTTPX.with(timeout: { connect_timeout: 10, read_timeout: 30 })

      def fetch
        body = client.get(@url).raise_for_status.body
        raise InvalidListError, "list is #{body.bytesize} bytes, we only take #{MAX_BYTES}" if body.bytesize > MAX_BYTES

        body.to_s.lines.map { _1.strip.downcase }.grep(BlockedDomain::FORMAT).select { BlockedDomain.registrable?(_1) }.uniq
      end

      def vetted(domains)
        raise InvalidListError, "list has #{domains.size} domains, we expect #{expected_size}" unless expected_size.cover?(domains.size)

        if (providers = domains & BlockedDomain::PROTECTED).any?
          raise InvalidListError, "list holds major email providers: #{providers.to_sentence}"
        end

        previous = BlockedDomain.disposable_email_list.count
        if expected_size.cover?(previous) && (domains.size - previous).abs.fdiv(previous) > max_change
          raise InvalidListError, "list went from #{previous} to #{domains.size} domains, more than the #{max_change} change we allow"
        end

        domains
      end

      def block(domains)
        synced_at = Time.current

        BlockedDomain.transaction do
          domains.each_slice(1_000) do |slice|
            # Hand added rows win, so conflicts only bump `updated_at` to keep them out of the sweep below.
            BlockedDomain.upsert_all slice.map { { name: _1, source: :disposable_email_list, created_at: synced_at, updated_at: synced_at } },
              unique_by: :name, update_only: %i[updated_at], record_timestamps: false
          end

          BlockedDomain.disposable_email_list.where(updated_at: ...synced_at).delete_all
        end
      end
  end
end
