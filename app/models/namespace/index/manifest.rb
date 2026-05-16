class Namespace::Index::Manifest < ApplicationRecord
  belongs_to :author, polymorphic: true, touch: true

  performs def append(versions)
    self.contents <<= Array(versions).map { _1.envelope ref_stamp: _1.ref }.join
    save!
  end

  performs def compact
    update! compacted_at: compacted_at = Time.current,
      contents: "#{compacted_at.iso8601}\n---\n#{composed_envelopes}"
  end

  private
    def composed_envelopes
      author.gems.filter_map { author.versions.latest_for(_1.name)&.envelope }.join
    end
end
