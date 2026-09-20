class Peak::Gem::Gemspec < Peak::Gem::Upload
  attr_accessor :published_at, :checksum
  attr_reader :spec

  def initialize(spec)
    @spec = spec
  end

  def package = raise("no package on a gemspec")

  private
    def rewinding = raise("can't rewind a gemspec")
end
