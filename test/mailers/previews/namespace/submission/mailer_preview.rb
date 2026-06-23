# Preview all emails at http://localhost:3000/rails/mailers/namespace/submission/mailer
class Namespace::Submission::MailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/namespace/submission/mailer/welcome
  def welcome
    Namespace::Submission.first.mailer.welcome
  end

  # Preview this email at http://localhost:3000/rails/mailers/namespace/submission/mailer/approved
  def approved
    Namespace::Submission.approved.first.mailer.approved
  end
end
