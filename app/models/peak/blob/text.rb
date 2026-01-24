class Peak::Blob::Text < ActiveStorage::Blob
  self.table_name = superclass.table_name
  attr_accessor :io

  after_create :upload

  def self.from(io, filename:)
    io = StringIO.new(io) if io.is_a?(String)
    io = build(io:, filename:) if io.is_a?(StringIO)
    io
  end

  def self.build(io:, **)
    super(io:, content_type: "text/plain", **).tap { _1.unfurl io, identify: false }
  end

  # TODO: Create a new service so we can append to actual storage?
  def path = Pathname(service.path_for(key))
  delegate :write, to: :path

  def upload
    upload_without_unfurling io
  end
end
