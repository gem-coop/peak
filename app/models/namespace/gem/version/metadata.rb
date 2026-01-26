class Namespace::Gem::Version::Metadata < ActiveRecord::AssociatedObject
  def line
    values.as_json.map { _1.join ":" }.join(",").presence&.prepend "|"
  end

  def values
    {checksum:, ruby:, rubygems:, published_at:}.compact_blank
  end
  delegate :checksum, :ruby, :rubygems, :published_at, to: :version
end
