# Preview all emails at http://localhost:3000/rails/mailers/user/email_verification/mailer
class User::EmailVerification::MailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user/email_verification/mailer/verification
  def verification
    User::EmailVerification.first.mailer
  end
end
