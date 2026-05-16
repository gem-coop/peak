class Namespace::Index::Manifest < ApplicationRecord
  belongs_to :author, polymorphic: true, touch: true
  delegate :gems, :versions, to: :author

  after_create :compact_later

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
      # TODO: later, use https://github.com/bensheldon/activerecord-has_some_of_many
      gems.find_each.pluck(:name).inject(+"") { |str, name| str << versions.latest_for(name)&.envelope.to_s }
    end
end
