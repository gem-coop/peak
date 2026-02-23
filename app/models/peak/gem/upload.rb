require "rubygems/package"

class Peak::Gem::Upload
  def self.read(io, **)
    IO.copy_stream io, tmpfile = Tempfile.new
    new(tmpfile, **)
  end

  attr_reader :tmpfile
  attr_accessor :published_at

  def initialize(tmpfile, published_at: nil)
    @tmpfile = tmpfile.tap(&:rewind)
    @published_at = published_at
    @package = nil
  end

  def package
    @package ||= rewinding { ::Gem::Package.new tmpfile }
  end
  delegate :spec, to: :package
  delegate :name, :executables, :licenses, :homepage, :metadata, to: :spec
  def ref = spec.version.to_s
  def ruby = spec.required_ruby_version.to_s
  def rubygems = spec.required_rubygems_version.to_s

  def requirement_triples
    spec.dependencies.select(&:runtime?).flat_map { |dep|
      dep.requirement.requirements.map { |operator, ref| [dep.name, operator, ref] }
    }
  end

  def links
    metadata.select { _1.end_with? "_uri" }.transform_keys { _1.delete_suffix("_uri").to_sym }.merge(homepage:).compact_blank
  end

  def unlink
    tmpfile.close!
  end

  def checksum
    rewinding { Digest::SHA256.file(tmpfile).hexdigest }
  end

  private
    def rewinding = yield.tap { tmpfile.rewind }
end
