# Preview all emails at http://localhost:3000/rails/mailers/user/push_key/mailer
class User::PushKey::MailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user/push_key/mailer/sign_in
  def sign_in
    User::PushKey.active.find_or_create_by(user: User.last).sign_in_mailer
  end
end
