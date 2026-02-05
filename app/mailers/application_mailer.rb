class ApplicationMailer < ActionMailer::Base
  default from: Mail::Address.new("Gem Coop <support@gem.coop>")
  layout "mailer"
end
