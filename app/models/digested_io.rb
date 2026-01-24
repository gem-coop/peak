class DigestedIO < Data.define(:buffer, :digest)
  def initialize(buffer: StringIO.new, digest: Digest::MD5.new) = super
  delegate :string, to: :buffer
  delegate :hexdigest, to: :digest

  def consume(enumerable, &)
    enumerable.inject(self) { |buf, value| buf << yield(value) }
  end

  def <<(chunk)
    buffer << chunk
    digest << chunk
    self
  end
end
