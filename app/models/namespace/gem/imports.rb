class Namespace::Gem::Imports < ActiveRecord::AssociatedObject
  # Call `index.compact` afterwards, as needed.
  performs def import_all(index)
    versions = gem.versions.where(index:)

    server_refs = server.refs
    stored_refs = versions.refs

    # Refs we have that the server doesn't have been yanked
    yanked_refs = stored_refs - server_refs
    versions.where(ref: yanked_refs).destroy_all

    # Refs the server has that we don't should be imported
    import_refs = server_refs - stored_refs - ignored_refs(gem.name)
    import_refs.each_with_object(+"") do |ref, errors|
      gemspec = Peak::Gem::Gemspec.new server.gemspec(ref)
      versions.system.new(ref:).consume(gemspec, index:, **publishing_ledger[ref])
    rescue => error
      errors << "#{ref}: #{error.inspect}\n"
    end => errors

    gem.reindex
  ensure
    raise errors unless errors.empty?
  end

  private
    delegate :server, to: :gem

    def publishing_ledger
      @publishing_ledger ||= server.versions_json.to_h do |json|
        key = json.values_at("number", "platform").join("-").chomp("-ruby")
        value = {published_at: json["created_at"], checksum: json["sha"]}
        [key, value]
      end.compact
    end

    def ignored_refs(name)
      # These versions are still included in RubyGems.org /info files,
      # even though the actual .gemspec and .gem files are invalid.
      # So we have to exclude them by hand.
      {
        "dwradcliffe-test-one" => ["0.0.1"],
        "rumai" => ["2.1.0", "3.0.0", "3.1.0", "3.2.0"],
        "dsad" => ["1.0.0"],
        "evri" => ["0.03", "0.04", "0.05", "0.06", "0.07"],
        "sevgi-derender" => ["0.73.0"],
        "test-html-sanitizer" => ["0.0.1", "0.0.2", "0.0.3"],
        "rubymisc" => ["0.0.1", "0.0.2", "0.0.3", "0.0.3.1"]
      }.fetch(name, [])
    end
end
