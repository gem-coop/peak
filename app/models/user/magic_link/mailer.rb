class User::MagicLink::Mailer < ApplicationMailer
  def sign_in
    @magic_link = params[:magic_link]
    mail to: @magic_link.user.email_address, subject: "Sign in to gem.coop"
  end
end
