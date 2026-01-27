class Namespace::Gem::Version::Metadata < ActiveRecord::AssociatedObject
  def line
    values.as_json.map { "#{_1}:#{join_value(_2)}" }.join(",").presence&.prepend "|"
  end
  def values = extract_from(version)

  def extract_from(store)
    KEYS.index_with { store.public_send _1 }.compact_blank
  end

  KEYS = %i[checksum ruby rubygems executables licenses published_at]
  delegate *KEYS, to: :version

  private
    def join_value(value)
      value.respond_to?(:join) ? value.join("&") : value
    end
end
