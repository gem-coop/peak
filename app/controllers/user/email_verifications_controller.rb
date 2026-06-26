class User::EmailVerificationsController < ApplicationController
  def new
  end

  def create
    verification = User::EmailVerification.find_by!(email_address: params[:email_address])

    if verification && !verification.verified?
      verification.deliver_later
      render Peak::Status("We've sent your verification email.")
    else
      render Peak::Error("That email address has already been verified."), status: :unprocessable_entity
    end
  end

  def show
    response.headers["Referrer-Policy"] = "no-referrer" # Keep the token URL out of the Referer header.
    verification = User::EmailVerification.find_by_token(params[:id])

    if verification
      verification.verify
      render Peak::Status("Your email's been verified!")
    else
      redirect_to new_user_email_verification_url, alert: "No verification found or it has expired. Request a new one here."
    end
  end
end
