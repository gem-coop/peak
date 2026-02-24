# Preview all emails at http://localhost:3000/rails/mailers/namespace/mailer
class Namespace::MailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/namespace/mailer/approved
  def approved
    Namespace.where.associated(:accesses).first.mailer.approved
  end
end
