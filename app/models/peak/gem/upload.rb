class Peak::Gem::Upload < Peak::Gem::Gemspec
  mattr_reader :limit, default: 50.megabytes

  def self.read(io, **)
    IO.copy_stream io, tmpfile = Tempfile.new
    new(tmpfile, **)
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

  def unlink
    tmpfile.close!
  end

  def checksum
    rewinding { Digest::SHA256.file(tmpfile).hexdigest }
  end

  private
    def rewinding = yield.tap { tmpfile.rewind }
end
