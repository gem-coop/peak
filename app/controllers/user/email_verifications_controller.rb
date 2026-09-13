class User::EmailVerificationsController < ApplicationController
  Success = Peak::Ok("We've sent your verification email.")

  rate_limit to: 1, within: 30.seconds, with: -> { render Success }, only: :create
  set_referrer_policy "no-referrer", only: :show

  def new
  end

  def create
    User::EmailVerification.find_by(params.permit(:email_address))&.deliver_pending_later
    render Success
  end

  def show
    verification = User::EmailVerification.find_by_token(params[:id])

    if verification
      verification.verify
      render Peak::Ok("Your email's been verified!")
    else
      redirect_to new_user_email_verification_url, alert: "No verification found or it has expired. Request a new one here."
    end
  end
end
