class Namespace::Index::Manifest < ApplicationRecord
  belongs_to :author, polymorphic: true, touch: true
  delegate :versions, to: :author

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
    def computed_contents
      versions.distinct_on_gem_name.latest_first.as_byline.inject(+"") { _1 << _2.envelope }
    end
end
