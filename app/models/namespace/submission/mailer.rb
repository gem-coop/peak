class Namespace::Submission::Mailer < ApplicationMailer
  default to: -> { ActionMailer::Address(@owner) }
  before_action { @owner = params[:submission].owner }

  def welcome
    mail subject: "Welcome to gem.coop"
  end

  def approved
    @namespace = params[:submission].namespace
    mail subject: "#{@namespace.name} approved!"
  end
end
