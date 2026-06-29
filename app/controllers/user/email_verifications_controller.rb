class User::EmailVerificationsController < ApplicationController
  Success = Peak::Status("We've sent your verification email.")

  rate_limit to: 1, within: 30.seconds, with: -> { render Success }, only: :create
  set_referrer_policy "strict-origin", only: :show

  before_action :set_email_verification, only: %i[show update]

  def new
  end

  def create
    verification = User::EmailVerification.find_by(email_address: params[:email_address])

    if verification && !verification.verified?
      verification.deliver_later
    end

    render Success
  end

  def show
  end

  def update
    @email_verification.verify
    render Peak::Status("Your email's been verified!")
  end

  private
    def set_email_verification
      @email_verification = User::EmailVerification.find_by_token(params[:token]) or
        redirect_to new_user_email_verification_url, alert: "No verification found or it has expired. Request a new one here."
    end
end
