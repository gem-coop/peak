class Namespace::Gem::Version::Metadata < ActiveRecord::AssociatedObject
  def line
    values.as_json.map { _1.join ":" }.join(",").presence&.prepend "|"
  end
  def values = extract_from(version)

  def extract_from(store)
    KEYS.index_with { store.public_send _1 }.compact_blank
  end

  KEYS = %i[checksum ruby rubygems published_at extensions]
  delegate *KEYS, to: :version
end
