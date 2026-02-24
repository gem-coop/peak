class Namespace::Mailer < ApplicationMailer
  before_action { @namespace = params[:namespace] }
  default to: -> { ActionMailer::Address @namespace.accesses.owner.first.user }

  def approved
    mail subject: "#{@namespace.name} approved!"
  end
end
