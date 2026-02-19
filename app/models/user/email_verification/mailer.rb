class User::EmailVerification::Mailer < ApplicationMailer
  def verification
    @verification = params[:email_verification]
    mail to: @verification.user.email_address, subject: "Verify your email and sign in"
  end
end
