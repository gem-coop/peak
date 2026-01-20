class Namespace::Gem::Version::Metadata < ApplicationRecord
  belongs_to :version

  def line
    part&.then { "|#{_1}" }
  end

  def part
    { checksum:, ruby:, rubygems: }.compact_blank.map { "#{_1}:#{_2}" }.join(",").presence
  end
end
