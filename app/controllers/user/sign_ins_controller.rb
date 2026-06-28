class User::SignInsController < ApplicationController
  rate_limit to: 3, within: 1.minute, with: :rate_limit_response, only: :create
  set_referrer_policy "no-referrer", only: :show

  def new
    stash_redirect_for :sign_in if redirect_url
  end

  def create
    User::MagicLink.find_by(email_address: params[:email_address])&.deliver_later

    render Peak::Status("Check your email for a sign-in link. Check spam too, just in case.")
  end

  def show
    if user = User::MagicLink.find_signed(params[:id])&.user
      attempted_access_url = discard_stashed_redirect_for(:sign_in)
      start_new_session_for user
      redirect_to attempted_access_url || root_url
    else
      redirect_to new_sign_in_url, alert: "That sign-in link is invalid or has expired. Try again."
    end
  end

  private
    def rate_limit_response
      render Peak::Error("Too many sign-in attempts. Try again later."), status: :too_many_requests
    end
end
