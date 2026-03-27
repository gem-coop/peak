class Current < ActiveSupport::CurrentAttributes
  attribute :session
  def session? = session.present?
  def user = session&.user

  attribute :uploads, default: []
  before_reset { uploads.each(&:unlink) }

  def upload_from(io)
    Peak::Gem::Upload.read(io).tap { uploads << _1 }
  end
end
