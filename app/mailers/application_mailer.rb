class ApplicationMailer < ActionMailer::Base
  # `email_address_with_name` ain't great.
  def ActionMailer.Address(addressed) = Mail::Address.new.tap do
    _1.address = addressed.email_address
    _1.display_name = addressed.name.presence
  end

  default from: -> { ActionMailer::Address(Peak.system_user) }
  layout "mailer"
end
