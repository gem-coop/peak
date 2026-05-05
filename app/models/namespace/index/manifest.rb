class Namespace::Index::Manifest < ApplicationRecord
  belongs_to :author, polymorphic: true, touch: true
  attribute :last_compacted_at, default: -> { Time.current }

  performs def compact
    update! last_compacted_at: last_compacted_at = Time.current,
      contents: "#{last_compacted_at.iso8601}\n---\n#{composed_envelopes}"
  end

  performs def append(versions)
    self.contents <<= Array(versions).map { _1.envelope ref_stamp: _1.ref }.join
    save!
  end

  private
    def composed_envelopes
      author.gems.map { author.versions.by_gem(_1.name).latest&.envelope }.compact.join
    end
end
