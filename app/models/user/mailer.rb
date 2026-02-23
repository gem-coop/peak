class User::Mailer < ApplicationMailer
  before_action { @user = params[:user] }
  default to: -> { @user.email_address }

  def welcome
    mail
  end
end
