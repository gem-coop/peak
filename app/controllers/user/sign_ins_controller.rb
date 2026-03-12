class User::SignInsController < ApplicationController
  rate_limit to: 3, within: 1.minute, with: :rate_limit_response, only: :create

  def new
    stash_redirect_for :sign_in if redirect_url
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      user.magic_link.deliver_later
    end

    render Peak::Status("Check your email for a sign-in link. Check spam too, just in case.")
  end

  private
    def rate_limit_response
      render Peak::Error("Too many sign-in attempts. Try again later."), status: :too_many_requests
    end
end
