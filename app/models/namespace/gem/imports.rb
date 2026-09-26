class Namespace::Gem::Imports < ActiveRecord::AssociatedObject
  # Call `index.compact` afterwards, as needed.
  performs def import_all(index)
    server_refs = server.refs
    stored_refs = versions.pluck(:ref)

    # Refs we have that the server doesn't have been yanked
    yanked_refs = stored_refs - server_refs
    versions.where(ref: yanked_refs).destroy_all

    # Refs the server has that we don't should be imported
    import_refs = server_refs - stored_refs
    import_refs.each do |ref|
      gemspec = Peak::Gem::Gemspec.new server.gemspec(ref)
      versions.system.new(ref:).consume(gemspec, index:, **publishing_ledger[ref])
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
