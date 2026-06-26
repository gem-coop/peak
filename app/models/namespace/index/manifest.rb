class Namespace::Index::Manifest < ApplicationRecord
  belongs_to :author, polymorphic: true, touch: true
  delegate :gems, :versions, to: :author

  # TODO: Look into why Active Job execution can't find Manifest, despite supposedly deferring jobs to after transaction commit now.
  after_create_commit :compact_later

  performs def append(versions)
    self.contents <<= Array(versions).map { _1.envelope ref_stamp: _1.ref }.join
    save!
  end

  performs def compact
    update! compacted_at: compacted_at = Time.current,
      contents: "#{compacted_at.iso8601}\n---\n#{computed_contents}"
  end

  private
    # One grouped query builds the same `name refs checksum` lines (gem-id order), no per-gem lookup.
    # TODO: could swap for https://github.com/bensheldon/activerecord-has_some_of_many if preferred.
    def computed_contents
      versions
        .reorder("namespace_gems.id", "namespace_gem_versions.published_at", "namespace_gem_versions.ref")
        .pluck("namespace_gems.name", "namespace_gem_versions.ref", "namespace_gem_versions.line")
        .group_by(&:first)
        .map { |name, rows| "#{name} #{rows.map { _1[1] }.join(",")} #{Digest::MD5.hexdigest(rows.map { _1[2] }.join)}\n" }
        .join
    end
end
