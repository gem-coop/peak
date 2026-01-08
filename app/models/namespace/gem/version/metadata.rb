class Namespace::Gem::Version::Metadata < ApplicationRecord
  belongs_to :version

  def line
    { checksum:, ruby:, rubygems: }.compact_blank.map { "#{_1}:#{_2}" }.join(",")
  end
end
