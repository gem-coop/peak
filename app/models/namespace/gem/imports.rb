class Namespace::Gem::Imports < ActiveRecord::AssociatedObject
  # Call `index.compact` afterwards, as needed.
  performs def import_all(index)
    known_refs = server.refs

    yanked_refs = versions.where.not(ref: known_refs).pluck(:ref)
    versions.where(ref: yanked_refs).destroy_all

    pending_refs = known_refs.then { _1.without versions.where(ref: _1).pluck(:ref) }
    pending_refs.each do |ref|
      upload = Peak::Gem::Gemspec.new server.gemspec(ref)
      versions.system.new(ref:).consume(upload, index:, **publishing_ledger[ref])
    end

    gem.reindex
  end

  private
    delegate :server, :versions, to: :gem

    def publishing_ledger
      @publishing_ledger ||= server.versions_json.to_h do |json|
        key = json.values_at("number", "platform").join("-").chomp("-ruby")
        value = {published_at: json["created_at"], checksum: json["sha"]}
        [key, value]
      end.compact
    end
end
