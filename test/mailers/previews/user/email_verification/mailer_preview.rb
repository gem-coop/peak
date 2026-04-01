# Preview all emails at http://localhost:3000/rails/mailers/user/email_verification/mailer
class User::EmailVerification::MailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user/email_verification/mailer/mailer
  def mailer
    User::EmailVerification.first.mailer
  end
end
