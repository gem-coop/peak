# Preview all emails at http://localhost:3000/rails/mailers/user/magic_link/mailer
class User::MagicLink::MailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user/magic_link/mailer/mailer
  def mailer
    User::MagicLink.first.mailer
  end
end
