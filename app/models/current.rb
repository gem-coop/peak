class Current < ActiveSupport::CurrentAttributes
  attribute :uploads, default: []
  before_reset { uploads.each(&:unlink) }

  def gem_upload(io, gemset:)
    Peak::Gem::Upload.read(io, gemset:).tap { uploads << _1 }
  end
end
