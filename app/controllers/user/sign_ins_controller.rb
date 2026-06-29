class User::SignInsController < ApplicationController
  rate_limit to: 3, within: 1.minute, with: :rate_limit_response, only: :create
  rate_limit to: 3, within: 1.minute, by: :email_address_rate_limiting_key, with: :rate_limit_response, only: :create
  set_referrer_policy "no-referrer", only: :show

  def new
    stash_redirect_for :sign_in if redirect_url
  end

  def create
    User::MagicLink.find_by(email_address: params[:email_address])&.deliver_later

    render Peak::Ok("Check your email for a sign-in link. Check spam too, just in case.")
  end

  def show
    if user = User::MagicLink.find_by_token(params[:id])&.user
      attempted_access_url = discard_stashed_redirect_for(:sign_in)
      start_new_session_for user
      redirect_to attempted_access_url || dashboard_url
    else
      redirect_to new_sign_in_url, alert: "That sign-in link is invalid or has expired. Try again."
    end
  end

  private
    def email_address_rate_limiting_key
      User.normalize_value_for :email_address, params[:email_address].to_s
    end

    def rate_limit_response
      render Peak::Error("Too many sign-in attempts. Try again later."), status: :too_many_requests
    end
end
