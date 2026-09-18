class Namespace::Gem::Imports < ActiveRecord::AssociatedObject
  # Call `index.compact` afterwards, as needed.
  performs def import_all(index)
    pending_refs.each { |ref| import_ref ref, index }
    gem.reindex
  end

  def import_ref(ref, index)
    upload = Package.new server.gemspec(ref)
    versions.system.new(ref:).consume(upload, index:, **publishing_ledger[ref])
  end

  def pending_refs
    server.refs.then { _1.without versions.where(ref: _1).pluck(:ref) }
  end

  private
    delegate :server, :versions, to: :gem

    class Package < Peak::Gem::Upload
      attr_reader :spec, :checksum

      def initialize(spec)
        @spec = spec
      end
    end

    def publishing_ledger
      @publishing_ledger ||= server.versions_json.to_h do |json|
        key = json.values_at("number", "platform").join("-").chomp("-ruby")
        value = {published_at: json["created_at"], checksum: json["sha"]}
        [key, value]
      end.compact
    end
end
