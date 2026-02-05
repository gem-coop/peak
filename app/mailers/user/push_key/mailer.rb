class User::PushKey::Mailer < ApplicationMailer
  def sign_in
    @push_key = params[:push_key]
    @token = @push_key.token
    mail to: @push_key.user.email_address, subject: "New Push Key"
  end
end
