class User::EmailVerificationsController < ApplicationController
  Created = Peak::Ok("We've sent your verification email.")

  rate_limit to: 1, within: 30.seconds, with: -> { render Created }, only: :create
  set_referrer_policy "no-referrer", only: :show

  def new
  end

  def create
    User::EmailVerification.find_by(params.permit(:email_address))&.deliver_pending_later
    Created
  end

  def show
    verification = User::EmailVerification.find_by_token(params[:id])

    if verification
      verification.verify
      Peak::Ok("Your email's been verified!")
    else
      redirect_to new_user_email_verification_url, alert: "No verification found or it has expired. Request a new one here."
    end
  end
end
