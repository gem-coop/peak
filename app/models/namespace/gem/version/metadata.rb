class Namespace::Gem::Version::Metadata < ActiveRecord::AssociatedObject
  def line
    values.as_json.map { "#{_1}:#{Peak::CompactIndex.safe(join_value(_2))}" }.join(",").presence&.prepend "|"
  end
  def values = extract_from(version)

  def extract_from(store)
    store.slice(*keys).compact_blank
  end

  mattr_reader :keys, default: %i[checksum ruby rubygems executables licenses published_at]
  delegate *keys, to: :version

  private
    def join_value(value)
      value.respond_to?(:join) ? value.join("&") : value
    end
end
