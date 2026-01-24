class Peak::Gem::Upload
  def self.read(io, **)
    tmpfile = Tempfile.new.tap { IO.copy_stream io, _1 }
    new(tmpfile, **)
  end

  attr_reader :tmpfile, :gemset

  def initialize(tmpfile, gemset:)
    @tmpfile, @gemset = tmpfile, gemset
    @tmpfile.rewind
    @gem = @version = @package = nil
  end

  def version
    @version ||= gem.versions.find_or_initialize_by(ref:)
  end

  def gem
    @gem ||= gemset.find_or_create_by!(name:)
  end

  def package
    @package ||= rewinding { ::Gem::Package.new tmpfile }
  end
  delegate :spec, to: :package
  delegate :name, to: :spec

  def ref = spec.version.to_s

  def unlink
    tmpfile.close!
  end

  def checksum
    rewinding { Digest::SHA256.file(tmpfile).hexdigest }
  end

  private
    def rewinding = yield.tap { tmpfile.rewind }
end
