class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :uploads, default: []
  before_reset { uploads.each(&:unlink) }

  def user = session&.user

  def upload_from(io)
    Peak::Gem::Upload.read(io).tap { uploads << _1 }
  end
end
