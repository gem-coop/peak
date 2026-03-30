class Current < ActiveSupport::CurrentAttributes
  attribute :session
  def user = session&.user
  def user? = user.present?
  def session? = session.present?

  attribute :uploads, default: []
  before_reset { uploads.each(&:unlink) }

  def upload_from(io)
    Peak::Gem::Upload.read(io).tap { uploads << _1 }
  end
end
