class User::EmailVerification < ActiveRecord::AssociatedObject
  generates_token expires_in: 24.hours, embed: -> { _1.email_address_verified_at&.to_i }

  has_mailer to: :user, subject: "Verify your email and sign in"

  def verify
    user.with_lock do
      return if verified?

      user.update! email_address_verified_at: Time.current
      user.submissions.pending.find_each(&:slack_notify_later)
    end
  end
  def verified? = user.verified?
end
