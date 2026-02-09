require "rubygems/package"

class Peak::Gem::Upload
  def self.read(io)
    new Tempfile.new.tap { IO.copy_stream io, _1 }
  end

  attr_reader :tmpfile

  def initialize(tmpfile)
    @tmpfile = tmpfile.tap(&:rewind)
    @package = nil
  end

  def package
    @package ||= rewinding { ::Gem::Package.new tmpfile }
  end
  delegate :spec, to: :package
  delegate :name, :executables, :licenses, to: :spec
  def ref = spec.version.to_s
  def ruby = spec.required_ruby_version.to_s
  def rubygems = spec.required_rubygems_version.to_s
  def published_at = nil

  def requirement_triples
    spec.dependencies.select(&:runtime?).flat_map { |dep|
      dep.requirement.requirements.map { |operator, ref| [dep.name, operator, ref] }
    }
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
