class Namespace::Gem::Imports < ActiveRecord::AssociatedObject
  def import_all
    pending_refs.each { |ref| import_ref ref }
    gem.index.compact
  end

  def import_ref(ref)
    upload = Peak::Gem::Upload.read server.download(ref), published_at: publishing_ledger[ref]
    versions.system.new(ref:).process(upload)
  end

  def pending_refs
    server.refs.then { _1.without versions.where(ref: _1).pluck(:ref) }
  end

  private
    delegate :server, :versions, to: :gem

    def publishing_ledger
      @publishing_ledger ||= server.versions_json.to_h { _1.values_at("number", "created_at") }.compact
    end
end
