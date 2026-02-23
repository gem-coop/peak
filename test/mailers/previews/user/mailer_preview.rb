# Preview all emails at http://localhost:3000/rails/mailers/user/mailer
class User::MailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user/mailer/welcome
  def welcome
    User.first.mailer.welcome
  end
end
