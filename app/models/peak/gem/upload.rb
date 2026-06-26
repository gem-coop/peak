class Peak::Gem::Upload
  mattr_reader :limit, default: 50.megabytes

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

  def slice(*keys)
    keys.index_with { public_send _1 }
  end

  def package
    @package ||= rewinding { ::Gem::Package.new tmpfile }
  end
  delegate :spec, to: :package
  delegate :name, :executables, :licenses, :summary, :homepage, :metadata, to: :spec
  def ruby = spec.required_ruby_version.to_s
  def rubygems = spec.required_rubygems_version.to_s

  def platform_id
    Peak::Platform.ids_from(platform_key).first
  end
  def platform_key = spec.platform.to_s
  def platform_ref = "#{spec.version}-#{spec.platform}".chomp("-ruby")

  def requirement_triples
    spec.dependencies.select(&:runtime?).flat_map { |dep|
      dep.requirement.requirements.map { |operator, ref| [dep.name, operator, ref] }
    }
  end

  # Persist only safe http(s) links; drop schemes a crafted gem could smuggle past gem build.
  def links
    metadata.select { _1.end_with? "_uri" }.transform_keys { _1.delete_suffix("_uri").to_sym }.merge(homepage:).compact_blank
      .select { |_, value| Peak::Gem::Link.safe? value }
  end

  def has_extensions? = spec.extensions.any?
  alias_method :has_extensions, :has_extensions?

  def unlink
    tmpfile.close!
  end

  def checksum
    rewinding { Digest::SHA256.file(tmpfile).hexdigest }
  end

  private
    def rewinding = yield.tap { tmpfile.rewind }
end
